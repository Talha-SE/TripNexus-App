import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_drawer.dart';
import '../auth/welcome_screen.dart';

class AdvisorDashboard extends StatefulWidget {
  const AdvisorDashboard({Key? key}) : super(key: key);

  @override
  State<AdvisorDashboard> createState() => _AdvisorDashboardState();
}

class _AdvisorDashboardState extends State<AdvisorDashboard> {
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
        return _buildBookingsTab();
      case 2:
        return _buildPackagesTab();
      case 3:
        return _buildAnalyticsTab();
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
            'Advisor Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your services and clients',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 24),
          Text(
            'Recent Bookings',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentBookings(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Bookings', '0', Icons.bookmark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Rating', '0.0', Icons.star)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Color(AppConfig.primaryColor)),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(AppConfig.textPrimaryColor),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Color(AppConfig.textSecondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionCard(
          Icons.add_box,
          'Create Package',
          'Add new travel packages',
          () {},
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          Icons.calendar_today,
          'Manage Schedule',
          'View and update availability',
          () {},
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          Icons.message,
          'Messages',
          'Chat with clients',
          () {},
        ),
      ],
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(AppConfig.primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Color(AppConfig.primaryColor)),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return Center(
      child: Text(
        'Bookings Tab - Coming Soon',
        style: GoogleFonts.poppins(fontSize: 18),
      ),
    );
  }

  Widget _buildPackagesTab() {
    return Center(
      child: Text(
        'Packages Tab - Coming Soon',
        style: GoogleFonts.poppins(fontSize: 18),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Center(
      child: Text(
        'Analytics Tab - Coming Soon',
        style: GoogleFonts.poppins(fontSize: 18),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Text(
        'Profile Tab - Coming Soon',
        style: GoogleFonts.poppins(fontSize: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Advisor Dashboard'),
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
        userRole: 'Travel Advisor',
        onLogout: _handleLogout,
      ),
      body: _buildDashboardContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outlined),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_outlined),
            selectedIcon: Icon(Icons.inventory),
            label: 'Packages',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
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
