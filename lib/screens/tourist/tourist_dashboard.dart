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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready for your next adventure?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          Text(
            'AI-Powered Features',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 16),
          _buildAIFeatures(),
          const SizedBox(height: 24),
          Text(
            'Your Recent Trips',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentTrips(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickAction(Icons.auto_awesome, 'AI Planner', () => _navigateToScreen(const AITripPlannerScreen())),
                    _buildQuickAction(Icons.camera_alt, 'Scan', () => _navigateToScreen(const LandmarkScannerScreen())),
                    _buildQuickAction(Icons.wb_sunny, 'Weather', () => _navigateToScreen(const WeatherScreen())),
                    _buildQuickAction(Icons.person_search, 'Advisors', () => _navigateToScreen(const AdvisorsSearchScreen())),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickAction(Icons.bookmark, 'Saved\nLandmarks', () => _navigateToScreen(const SavedLandmarksScreen())),
                    _buildQuickAction(Icons.auto_stories, 'Saved\nPlans', () => _navigateToScreen(const SavedTripPlansScreen())),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(AppConfig.primaryColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Color(AppConfig.primaryColor), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12),
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
    return Column(
      children: [
        _buildFeatureCard(
          Icons.smart_toy,
          'AI Travel Assistant',
          'Get personalized recommendations',
          Color(AppConfig.primaryColor),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          Icons.eco,
          'Eco-Friendly Options',
          'Discover sustainable travel choices',
          Color(AppConfig.accentColor),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          Icons.event,
          'Local Events',
          'Find exciting events at your destination',
          Color(AppConfig.secondaryColor),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle, Color color) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }

  Widget _buildRecentTrips() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.explore_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No trips yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _navigateToScreen(const CreateTripScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConfig.primaryColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Your First Trip'),
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
      appBar: AppBar(
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
