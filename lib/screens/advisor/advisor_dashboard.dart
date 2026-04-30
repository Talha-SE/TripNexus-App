import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../config/app_config.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/package_service.dart';
import '../../services/mongodb_service.dart';
import '../../services/blockchain_service.dart';
import '../../widgets/custom_drawer.dart';
import '../auth/welcome_screen.dart';
import 'create_package_screen.dart';
import 'advisor_packages_screen.dart';
import 'advisor_profile_screen.dart';
import 'advisor_messages_screen.dart';

// Helper class to store booking with resolved names
class _BookingDisplay {
  final PackageBooking booking;
  final String packageName;
  final String travelerName;

  _BookingDisplay({
    required this.booking,
    required this.packageName,
    required this.travelerName,
  });
}

// Helper class for review analytics
class _ReviewAnalytics {
  final String packageId;
  final String packageName;
  final List<Map<String, dynamic>> reviews;
  final double averageRating;
  final int totalReviews;

  _ReviewAnalytics({
    required this.packageId,
    required this.packageName,
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
  });
}

// Helper function to extract hex string from ObjectId format
String _extractHexString(String id) {
  // If the ID contains ObjectId("..."), extract just the hex string
  final match = RegExp(r'ObjectId\("([0-9a-fA-F]{24})"\)').firstMatch(id);
  if (match != null) {
    return match.group(1)!;
  }
  // Otherwise return as-is (already a plain hex string)
  return id;
}

class AdvisorDashboard extends StatefulWidget {
  const AdvisorDashboard({Key? key}) : super(key: key);

  @override
  State<AdvisorDashboard> createState() => _AdvisorDashboardState();
}

class _AdvisorDashboardState extends State<AdvisorDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _advisorName = 'Advisor';
  String _advisorRole = 'Travel Advisor';
  String? _advisorId;

  // Bookings state
  List<PackageBooking> _bookings = [];
  List<_BookingDisplay> _bookingDisplays = [];
  bool _bookingsLoading = false;
  String? _bookingsError;
  String _bookingFilter = 'all'; // all, pending, accepted, rejected, completed

  // Notification counters
  int _unreadMessagesCount = 0;
  int _newReviewsCount = 0;

  // Analytics state
  List<_ReviewAnalytics> _reviewsAnalytics = [];
  bool _analyticsLoading = false;
  String? _analyticsError;

  @override
  void initState() {
    super.initState();
    _loadAdvisorInfo();
    _loadNotificationCounts();
  }

  Future<void> _loadAdvisorInfo() async {
    try {
      final authService = await AuthService.getInstance();
      final user = authService.currentUser;
      if (user != null && mounted) {
        setState(() {
          _advisorName = user.fullName.split(' ').first;
          _advisorRole = user.role == UserRole.advisorAgency
              ? 'Travel Agency'
              : 'Travel Advisor';
          _advisorId = user.id;
        });
      }
    } catch (_) {}
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
      transitionBuilder: (child, animation) {
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
        return _buildBookingsTab();
      case 2:
        return const AdvisorPackagesScreen();
      case 3:
        return _buildAnalyticsTab();
      case 4:
        return const AdvisorMessagesScreen();
      case 5:
        return const AdvisorProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  // ─────────────────────────── HOME TAB ──────────────────────────────

  Widget _buildHomeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      color: bgColor,
      child: RefreshIndicator(
        onRefresh: _loadAdvisorInfo,
        displacement: 100,
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
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Quick Actions'),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Getting Started'),
                    const SizedBox(height: 16),
                    _buildTipsCards(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [primaryColor, const Color(0xFF1565C0)],
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
          // Decorative circle
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
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
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
                          _buildHeaderIconButton(
                            icon: Icons.notifications_none_rounded,
                            onTap: () {},
                            showBorder: false,
                            showBackground: false,
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
                  Text(
                    'Hello, $_advisorName!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage Your\n$_advisorRole Hub',
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Verified $_advisorRole',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
        letterSpacing: 0.5,
      ),
    );
  }

  // ─────────────────────────── STATS ROW ─────────────────────────────

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 320;
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Packages',
                value: '0',
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFF2196F3),
                bgColor: const Color(0xFFE3F2FD),
              ),
            ),
            SizedBox(width: isNarrow ? 8 : 12),
            Expanded(
              child: _buildStatCard(
                title: 'Bookings',
                value: '0',
                icon: Icons.bookmark_rounded,
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
              ),
            ),
            SizedBox(width: isNarrow ? 8 : 12),
            Expanded(
              child: _buildStatCard(
                title: 'Rating',
                value: '—',
                icon: Icons.star_rounded,
                color: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.15) : bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── QUICK ACTIONS ─────────────────────────

  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 400 ? 4 : 4;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 20,
          crossAxisSpacing: 12,
          padding: EdgeInsets.zero,
          childAspectRatio: 0.7,
          children: [
            _buildQuickActionItem(
              Icons.add_box_rounded,
              'Create\nPackage',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePackageScreen(),
                ),
              ),
              const Color(0xFFE3F2FD),
              const Color(0xFF2196F3),
            ),
            _buildQuickActionItem(
              Icons.inventory_2_rounded,
              'My\nPackages',
              () => setState(() => _selectedIndex = 2),
              const Color(0xFFF3E5F5),
              const Color(0xFF9C27B0),
            ),
            _buildQuickActionItem(
              Icons.chat_bubble_rounded,
              'Messages',
              () => setState(() => _selectedIndex = 4),
              const Color(0xFFE8F5E9),
              const Color(0xFF4CAF50),
            ),
            _buildQuickActionItem(
              Icons.person_rounded,
              'Profile',
              () => setState(() => _selectedIndex = 5),
              const Color(0xFFFFF3E0),
              const Color(0xFFFF9800),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionItem(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color bgColor,
    Color iconColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── TIPS CARDS ────────────────────────────

  Widget _buildTipsCards() {
    return SizedBox(
      height: 175,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          _buildTipCard(
            icon: Icons.rocket_launch_rounded,
            title: 'Go Live Fast',
            subtitle: 'Create a package and make\nit live to start earning',
            color: Color(AppConfig.primaryColor),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreatePackageScreen(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildTipCard(
            icon: Icons.star_half_rounded,
            title: 'Build Reputation',
            subtitle: 'Respond fast to clients to\nboost your rating',
            color: const Color(0xFFF59E0B),
            onTap: () => setState(() => _selectedIndex = 4),
          ),
          const SizedBox(width: 16),
          _buildTipCard(
            icon: Icons.analytics_rounded,
            title: 'Track Revenue',
            subtitle: 'View bookings and earnings\nin the Analytics tab',
            color: const Color(0xFF10B981),
            onTap: () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : color.withOpacity(0.06),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? color.withOpacity(0.1)
                        : color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: isDark ? Colors.white38 : color.withOpacity(0.3),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark
                    ? Colors.white60
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                height: 1.45,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────  PLACEHOLDER TABS  ─────────────────────────────

  // ─────────────────── NOTIFICATION SYSTEM ──────────────────────────

  Future<void> _loadNotificationCounts() async {
    if (_advisorId == null) {
      await _loadAdvisorInfo();
      if (_advisorId == null) return;
    }

    try {
      final mongoService = await MongoDBService.getInstance();

      // Count unread messages
      final messagesCollection = mongoService.getPackageMessagesCollection();
      final unreadMessages = await messagesCollection.count({
        'receiverId': _advisorId,
        'isRead': false,
      });

      // Count bookings with new reviews (completed & reviewSubmitted recently)
      final bookingsCollection = mongoService.getPackageBookingsCollection();
      final recentReviews = await bookingsCollection.count({
        'advisorId': _advisorId,
        'reviewSubmitted': true,
        'status': 'completed',
      });

      if (mounted) {
        setState(() {
          _unreadMessagesCount = unreadMessages;
          _newReviewsCount = recentReviews;
        });
      }
    } catch (e) {
      print('Error loading notification counts: $e');
    }
  }

  // ─────────────────────── ANALYTICS TAB ────────────────────────────

  Future<void> _loadReviewsAnalytics() async {
    if (_advisorId == null) {
      await _loadAdvisorInfo();
      if (_advisorId == null) return;
    }

    setState(() {
      _analyticsLoading = true;
      _analyticsError = null;
    });

    try {
      // Get all packages for this advisor
      final packageService = await PackageService.getInstance();
      final packages = await packageService.getAdvisorPackages(_advisorId!);

      if (packages.isEmpty) {
        setState(() {
          _analyticsLoading = false;
          _reviewsAnalytics = [];
        });
        return;
      }

      final mongoService = await MongoDBService.getInstance();
      final reviewsCollection = mongoService.getBlockchainReviewsCollection();
      final packageIds = packages
          .where((pkg) => pkg.id != null)
          .map((pkg) => pkg.id!)
          .toList();

      final storedReviewDocs = packageIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await reviewsCollection
                .find(mongo.where.oneFrom('packageId', packageIds))
                .toList();

      final reviewsByPackage = <String, List<Map<String, dynamic>>>{};
      for (final doc in storedReviewDocs) {
        final packageId = doc['packageId']?.toString();
        if (packageId == null || packageId.isEmpty) {
          continue;
        }

        final rating = (doc['rating'] as num?)?.toInt() ?? 0;
        if (rating < 1 || rating > 5) {
          continue;
        }

        final rawTimestamp = doc['createdAt'] ?? doc['timestamp'];
        DateTime timestamp;
        if (rawTimestamp is DateTime) {
          timestamp = rawTimestamp;
        } else if (rawTimestamp is String) {
          timestamp = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
        } else {
          timestamp = DateTime.now();
        }

        final travelerNameRaw = (doc['travelerName'] as String?)?.trim() ?? '';

        reviewsByPackage.putIfAbsent(packageId, () => []).add({
          'traveler': doc['traveler']?.toString() ?? '',
          'travelerName': travelerNameRaw.isEmpty
              ? 'Traveler'
              : travelerNameRaw,
          'rating': rating,
          'comment': (doc['comment'] as String?)?.trim() ?? '',
          'timestamp': timestamp,
          'txHash': doc['txHash']?.toString(),
          'source': 'indexed',
        });
      }

      for (final entry in reviewsByPackage.entries) {
        entry.value.sort(
          (a, b) => (b['timestamp'] as DateTime).compareTo(
            a['timestamp'] as DateTime,
          ),
        );
      }

      // Get blockchain service
      BlockchainService? blockchainService;
      try {
        blockchainService = await BlockchainService.getInstance();
      } catch (e) {
        print('⚠️ BlockchainService not available: $e');
      }

      // Build review analytics with indexed DB first and blockchain fallback.
      final List<_ReviewAnalytics> analytics = [];

      for (final package in packages) {
        if (package.id == null) {
          continue;
        }

        final packageId = package.id!;
        final enrichedReviews = List<Map<String, dynamic>>.from(
          reviewsByPackage[packageId] ?? const <Map<String, dynamic>>[],
        );

        if (enrichedReviews.isEmpty && blockchainService != null) {
          try {
            final chainReviews = await blockchainService.getReviews(packageId);

            for (final review in chainReviews) {
              enrichedReviews.add({
                ...review,
                'travelerName': 'Traveler',
                'txHash': null,
                'source': 'blockchain',
              });
            }
          } catch (e) {
            print('Error fetching on-chain reviews for package $packageId: $e');
          }
        }

        if (enrichedReviews.isEmpty) {
          continue;
        }

        enrichedReviews.sort(
          (a, b) => (b['timestamp'] as DateTime).compareTo(
            a['timestamp'] as DateTime,
          ),
        );

        try {
          // Calculate average rating
          final avgRating = enrichedReviews.isEmpty
              ? 0.0
              : enrichedReviews
                        .map((r) => (r['rating'] as num).toDouble())
                        .reduce((a, b) => a + b) /
                    enrichedReviews.length;

          analytics.add(
            _ReviewAnalytics(
              packageId: packageId,
              packageName: package.title,
              reviews: enrichedReviews,
              averageRating: avgRating,
              totalReviews: enrichedReviews.length,
            ),
          );
        } catch (e) {
          print('Error preparing reviews for package $packageId: $e');
        }
      }

      // Sort by total reviews descending
      analytics.sort((a, b) => b.totalReviews.compareTo(a.totalReviews));

      if (mounted) {
        setState(() {
          _reviewsAnalytics = analytics;
          _analyticsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reviews analytics: $e');
      if (mounted) {
        setState(() {
          _analyticsError = 'Failed to load reviews';
          _analyticsLoading = false;
        });
      }
    }
  }

  // ─────────────────────── BOOKINGS TAB ────────────────────────────

  Future<void> _loadBookings() async {
    if (_advisorId == null) {
      await _loadAdvisorInfo();
      if (_advisorId == null) return;
    }
    setState(() {
      _bookingsLoading = true;
      _bookingsError = null;
    });
    try {
      final service = await PackageService.getInstance();
      final bookings = await service.getAdvisorBookings(_advisorId!);

      // Fetch package names and traveler names for each booking
      final mongoService = await MongoDBService.getInstance();
      final packagesCollection = mongoService.getPackagesCollection();
      final usersCollection = mongoService.getUsersCollection();

      final List<_BookingDisplay> displays = [];

      for (final booking in bookings) {
        String packageName = 'Unknown Package';
        String travelerName = 'Unknown User';

        try {
          // Get package name
          final packageHexId = _extractHexString(booking.packageId);
          final packageDoc = await packagesCollection.findOne({
            '_id': mongo.ObjectId.fromHexString(packageHexId),
          });
          if (packageDoc != null) {
            packageName = packageDoc['title'] as String? ?? 'Unknown Package';
          }
        } catch (e) {
          print('Error fetching package: $e');
        }

        try {
          // Get traveler name
          final travelerHexId = _extractHexString(booking.travelerId);
          final travelerDoc = await usersCollection.findOne({
            '_id': mongo.ObjectId.fromHexString(travelerHexId),
          });
          if (travelerDoc != null) {
            travelerName = travelerDoc['fullName'] as String? ?? 'Unknown User';
          }
        } catch (e) {
          print('Error fetching traveler: $e');
        }

        displays.add(
          _BookingDisplay(
            booking: booking,
            packageName: packageName,
            travelerName: travelerName,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _bookings = bookings;
          _bookingDisplays = displays;
          _bookingsLoading = false;
        });
        // Refresh notification counts
        _loadNotificationCounts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookingsLoading = false;
          _bookingsError = e.toString();
        });
      }
    }
  }

  Future<void> _updateBookingStatus(
    PackageBooking booking,
    String newStatus,
  ) async {
    try {
      final service = await PackageService.getInstance();
      final collection = service.getBookingsCollectionPublic();

      // Extract hex string and convert to ObjectId for MongoDB update
      final hexId = _extractHexString(booking.id!);
      final result = await collection.updateOne(
        {'_id': mongo.ObjectId.fromHexString(hexId)},
        {
          r'$set': {'status': newStatus},
        },
      );

      if (result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking ${newStatus == "accepted"
                  ? "accepted"
                  : newStatus == "rejected"
                  ? "declined"
                  : "updated"} successfully',
            ),
            backgroundColor: newStatus == 'accepted'
                ? const Color(0xFF10B981)
                : newStatus == 'rejected'
                ? Colors.red
                : Color(AppConfig.primaryColor),
          ),
        );
      }

      await _loadBookings();
    } catch (e) {
      print('Error updating booking status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBookingsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    // Load on first visit
    if (!_bookingsLoading &&
        _bookingDisplays.isEmpty &&
        _bookingsError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookings());
    }

    final filtered = _bookingFilter == 'all'
        ? _bookingDisplays
        : _bookingDisplays
              .where((b) => b.booking.status == _bookingFilter)
              .toList();

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              16,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookings',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${_bookings.length} total request${_bookings.length == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadBookings,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Color(AppConfig.primaryColor),
                  ),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // ── Filter chips ──
          Container(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _bookingChip('All', 'all', isDark),
                  const SizedBox(width: 8),
                  _bookingChip('Pending', 'pending', isDark),
                  const SizedBox(width: 8),
                  _bookingChip('Accepted', 'accepted', isDark),
                  const SizedBox(width: 8),
                  _bookingChip('Rejected', 'rejected', isDark),
                  const SizedBox(width: 8),
                  _bookingChip('Completed', 'completed', isDark),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Content ──
          Expanded(
            child: _bookingsLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookingsError != null
                ? _buildBookingsError(isDark)
                : filtered.isEmpty
                ? _buildBookingsEmpty(isDark)
                : RefreshIndicator(
                    onRefresh: _loadBookings,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _buildBookingCard(filtered[i], isDark),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _bookingChip(String label, String value, bool isDark) {
    final selected = _bookingFilter == value;
    final primary = Color(AppConfig.primaryColor);
    return GestureDetector(
      onTap: () => setState(() => _bookingFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? primary.withOpacity(0.12)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primary.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? primary
                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: Color(0xFF10B981),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _bookingFilter == 'all'
                ? 'No Bookings Yet'
                : 'No ${_bookingFilter[0].toUpperCase()}${_bookingFilter.substring(1)} Bookings',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When travellers book your packages\nthey will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFF64748B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load bookings',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConfig.primaryColor),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(_BookingDisplay bookingDisplay, bool isDark) {
    final booking = bookingDisplay.booking;
    Color statusColor;
    IconData statusIcon;
    switch (booking.status) {
      case 'accepted':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'completed':
        statusColor = Color(AppConfig.primaryColor);
        statusIcon = Icons.verified_rounded;
        break;
      default: // pending
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule_rounded;
    }

    final dateStr =
        '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}';
    final createdStr =
        '${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year}';

    // RepaintBoundary prevents unnecessary repaints of this card
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: status badge + amount
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.status[0].toUpperCase() +
                          booking.status.substring(1),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${booking.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(AppConfig.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Package & traveller info (now with resolved names)
              _infoRow(
                Icons.inventory_2_rounded,
                'Package',
                bookingDisplay.packageName,
                isDark,
              ),
              const SizedBox(height: 6),
              _infoRow(
                Icons.person_rounded,
                'Traveller',
                bookingDisplay.travelerName,
                isDark,
              ),
              const SizedBox(height: 6),
              _infoRow(
                Icons.calendar_today_rounded,
                'Trip Date',
                dateStr,
                isDark,
              ),
              const SizedBox(height: 6),
              _infoRow(
                Icons.payment_rounded,
                'Payment',
                booking.paymentMethod.toUpperCase(),
                isDark,
              ),
              const SizedBox(height: 6),
              _infoRow(
                Icons.access_time_rounded,
                'Requested',
                createdStr,
                isDark,
              ),
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(Icons.notes_rounded, 'Notes', booking.notes!, isDark),
              ],
              // Action buttons (only for pending)
              if (booking.status == 'pending') ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _updateBookingStatus(booking, 'rejected'),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(
                          'Decline',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateBookingStatus(booking, 'accepted'),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          'Accept',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Mark complete (only for accepted)
              if (booking.status == 'accepted') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateBookingStatus(booking, 'completed'),
                    icon: const Icon(Icons.verified_rounded, size: 18),
                    label: Text(
                      'Mark as Completed',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(AppConfig.primaryColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              // Review indicator for completed bookings
              if (booking.status == 'completed' && booking.reviewSubmitted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade50, Colors.blue.shade50],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_tree_rounded,
                          size: 16,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blockchain Review Received',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade700,
                              ),
                            ),
                            Text(
                              'Traveler submitted an immutable review',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ), // RepaintBoundary
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    // Load analytics on first view
    if (_reviewsAnalytics.isEmpty &&
        !_analyticsLoading &&
        _analyticsError == null) {
      Future.microtask(() => _loadReviewsAnalytics());
    }

    return Container(
      color: bgColor,
      child: RefreshIndicator(
        onRefresh: _loadReviewsAnalytics,
        displacement: 100,
        color: Color(AppConfig.primaryColor),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF59E0B),
                      const Color(0xFFF59E0B).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.rate_review_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Blockchain Reviews',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Immutable feedback from travelers',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_reviewsAnalytics.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildAnalyticsStatCard(
                            'Total Reviews',
                            _reviewsAnalytics
                                .fold<int>(
                                  0,
                                  (sum, item) => sum + item.totalReviews,
                                )
                                .toString(),
                            Icons.comment_rounded,
                            isDark: false,
                          ),
                          const SizedBox(width: 12),
                          _buildAnalyticsStatCard(
                            'Packages Reviewed',
                            _reviewsAnalytics.length.toString(),
                            Icons.inventory_2_rounded,
                            isDark: false,
                          ),
                          const SizedBox(width: 12),
                          _buildAnalyticsStatCard(
                            'Avg Rating',
                            _reviewsAnalytics.isEmpty
                                ? '0.0'
                                : (_reviewsAnalytics
                                              .map((e) => e.averageRating)
                                              .reduce((a, b) => a + b) /
                                          _reviewsAnalytics.length)
                                      .toStringAsFixed(1),
                            Icons.star_rounded,
                            isDark: false,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Content
            if (_analyticsLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(AppConfig.primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading blockchain reviews...',
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_analyticsError != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _analyticsError!,
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReviewsAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_reviewsAnalytics.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.rate_review_outlined,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Reviews Yet',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Blockchain reviews from travelers\\nwill appear here',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final analytics = _reviewsAnalytics[index];
                    return _buildPackageReviewCard(analytics, isDark);
                  }, childCount: _reviewsAnalytics.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsStatCard(
    String label,
    String value,
    IconData icon, {
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageReviewCard(_ReviewAnalytics analytics, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.1),
                  const Color(0xFFF59E0B).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.card_travel_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analytics.packageName,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < analytics.averageRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 16,
                              color: const Color(0xFFF59E0B),
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${analytics.averageRating.toStringAsFixed(1)} • ${analytics.totalReviews} ${analytics.totalReviews == 1 ? 'review' : 'reviews'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reviews list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: analytics.reviews.length,
            separatorBuilder: (context, index) => Divider(
              height: 24,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final review = analytics.reviews[index];
              return _buildReviewItem(review, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review, bool isDark) {
    final rating = review['rating'] as int;
    final comment = review['comment'] as String;
    final travelerName = review['travelerName'] as String;
    final timestamp = review['timestamp'] as DateTime;
    final travelerAddress = review['traveler']?.toString() ?? '';
    final txHash = review['txHash']?.toString();
    final source = review['source']?.toString() ?? 'blockchain';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          travelerName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: Colors.purple.shade700,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              source == 'indexed' ? 'Indexed' : 'Blockchain',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimestamp(timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 16,
                  color: const Color(0xFFF59E0B),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          comment.isEmpty ? 'No comment provided.' : comment,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 12,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                travelerAddress.isEmpty
                    ? 'Traveler identity protected'
                    : _shortHash(travelerAddress),
                style: GoogleFonts.sourceCodePro(
                  fontSize: 10,
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
        if (txHash != null && txHash.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.link_rounded,
                size: 12,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Tx: ${_shortHash(txHash)}',
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 10,
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _shortHash(String value, {int start = 6, int end = 4}) {
    if (value.length <= start + end) {
      return value;
    }
    return '${value.substring(0, start)}...${value.substring(value.length - end)}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 30) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // ─────────────────────────  NAV BAR  ──────────────────────────────

  Widget _buildFloatingNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);

    final items = [
      (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
      (Icons.bookmark_outline, Icons.bookmark_rounded, 'Bookings'),
      (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Packages'),
      (Icons.analytics_outlined, Icons.analytics_rounded, 'Analytics'),
      (Icons.chat_bubble_outline, Icons.chat_bubble_rounded, 'Messages'),
      (Icons.person_outline, Icons.person_rounded, 'Profile'),
    ];

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
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.92)
                  : Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isSelected = _selectedIndex == index;
                final item = items[index];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedIndex = index);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isSelected ? 44 : 0,
                            height: isSelected ? 4 : 0,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isSelected ? item.$2 : item.$1,
                                size: 22,
                                color: isSelected
                                    ? primaryColor
                                    : (isDark
                                          ? Colors.white38
                                          : Colors.grey.shade400),
                              ),
                              // Notification badges
                              if (index == 4 &&
                                  _unreadMessagesCount > 0) // Messages tab
                                Positioned(
                                  right: -8,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      _unreadMessagesCount > 9
                                          ? '9+'
                                          : _unreadMessagesCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              if (index == 1 &&
                                  _newReviewsCount > 0) // Bookings tab
                                Positioned(
                                  right: -8,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      _newReviewsCount > 9
                                          ? '9+'
                                          : _newReviewsCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$3,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────  SCAFFOLD  ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      // Prevent accidental logout when pressing back on the dashboard
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
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        drawer: CustomDrawer(
          userRole: 'Travel Advisor',
          onLogout: _handleLogout,
        ),
        body: Stack(
          children: [
            _buildDashboardContent(),
            // Bottom gradient fade for nav bar
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
                        (isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC))
                            .withOpacity(0),
                        (isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC))
                            .withOpacity(0.95),
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
}
