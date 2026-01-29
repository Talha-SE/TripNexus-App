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
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildTripsTab();
      case 2:
        return _buildExploreTab();
      case 3:
        return _buildAdvisorsTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConfig.textPrimaryColor),
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickActions(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI-Powered Features',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConfig.textPrimaryColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAIFeatures(),
                const SizedBox(height: 32),
                Text(
                  'Your Recent Trips',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConfig.textPrimaryColor),
                  ),
                ),
                const SizedBox(height: 16),
                _buildRecentTrips(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
      decoration: BoxDecoration(
        color: Color(AppConfig.primaryColor),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(AppConfig.primaryColor).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready for your next adventure?',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Search Bar Placeholder
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Text(
                    'Where do you want to go?',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 0.85,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildQuickActionItem(Icons.auto_awesome, 'AI Planner', () => _navigateToScreen(const AITripPlannerScreen()), Colors.purple.shade100, Colors.purple),
        _buildQuickActionItem(Icons.camera_alt, 'Scan', () => _navigateToScreen(const LandmarkScannerScreen()), Colors.blue.shade100, Colors.blue),
        _buildQuickActionItem(Icons.wb_sunny, 'Weather', () => _navigateToScreen(const WeatherScreen()), Colors.orange.shade100, Colors.orange),
        _buildQuickActionItem(Icons.person_search, 'Advisors', () => _navigateToScreen(const AdvisorsSearchScreen()), Colors.green.shade100, Colors.green),
        _buildQuickActionItem(Icons.bookmark, 'Saved\nLandmarks', () => _navigateToScreen(const SavedLandmarksScreen()), Colors.red.shade100, Colors.red),
        _buildQuickActionItem(Icons.auto_stories, 'Saved\nPlans', () => _navigateToScreen(const SavedTripPlansScreen()), Colors.teal.shade100, Colors.teal),
      ],
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, VoidCallback onTap, Color bgColor, Color iconColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
        children: [
          _buildFeatureCard(
            Icons.smart_toy,
            'AI Travel Assistant',
            'Get personalized\nrecommendations',
            Color(AppConfig.primaryColor),
            Colors.blue.shade50,
          ),
          const SizedBox(width: 16),
          _buildFeatureCard(
            Icons.eco,
            'Eco-Friendly',
            'Sustainable travel\nchoices for you',
            Color(AppConfig.accentColor),
            Colors.green.shade50,
          ),
          const SizedBox(width: 16),
          _buildFeatureCard(
            Icons.event,
            'Local Events',
            'Find exciting events\nat your destination',
            Color(AppConfig.secondaryColor),
            Colors.orange.shade50,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle, Color color, Color bgColor) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Color(AppConfig.textSecondaryColor),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.flight_takeoff, size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'No trips planned yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start planning your dream vacation today!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _navigateToScreen(const CreateTripScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConfig.primaryColor),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Create New Trip'),
          ),
        ],
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
      appBar: (_selectedIndex == 0 || _selectedIndex == 4)
          ? null
          : AppBar(
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
            ),
      drawer: CustomDrawer(
        userRole: 'Tourist',
        onLogout: _handleLogout,
      ),
      body: _buildDashboardContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_outlined),
            selectedIcon: Icon(Icons.flight),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_search_outlined),
            selectedIcon: Icon(Icons.person_search),
            label: 'Advisors',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
