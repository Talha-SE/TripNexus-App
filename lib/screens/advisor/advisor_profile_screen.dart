import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../settings/settings_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/privacy_security_screen.dart';

class AdvisorProfileScreen extends StatefulWidget {
  const AdvisorProfileScreen({super.key});

  @override
  State<AdvisorProfileScreen> createState() => _AdvisorProfileScreenState();
}

class _AdvisorProfileScreenState extends State<AdvisorProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final authService = await AuthService.getInstance();
      setState(() {
        _user = authService.currentUser;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Unable to load profile',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Color(AppConfig.textSecondaryColor),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildInfoSection(),
                const SizedBox(height: 24),
                _buildSettingsOptions(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isIndividual = _user!.role == UserRole.advisorIndividual;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConfig.primaryColor),
            Color(AppConfig.primaryColor).withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: Text(
                _user!.fullName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConfig.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user!.fullName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isIndividual ? 'Individual Advisor' : 'Agency Advisor',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (_user!.businessName != null) ...[
              const SizedBox(height: 8),
              Text(
                _user!.businessName!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.star,
            _user!.rating?.toStringAsFixed(1) ?? 'N/A',
            'Rating',
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.bookmark,
            '${_user!.totalBookings ?? 0}',
            'Bookings',
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Color(AppConfig.textSecondaryColor).withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppConfig.textPrimaryColor),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, _user!.email),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, _user!.phoneNumber),
            if (_user!.address != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on, _user!.address!),
            ],
            if (_user!.country != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.public, _user!.country!),
            ],
            if (_user!.expertise != null) ...[
              const Divider(height: 32),
              Text(
                'Expertise',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConfig.textPrimaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _user!.expertise!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Color(AppConfig.textSecondaryColor),
                ),
              ),
            ],
            if (_user!.bio != null) ...[
              const Divider(height: 32),
              Text(
                'About',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConfig.textPrimaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _user!.bio!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Color(AppConfig.textSecondaryColor),
                ),
              ),
            ],
            if (_user!.languages != null && _user!.languages!.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Languages',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConfig.textPrimaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _user!.languages!.map((lang) {
                  return Chip(
                    label: Text(lang),
                    backgroundColor: Color(AppConfig.primaryColor).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Color(AppConfig.primaryColor),
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Color(AppConfig.textSecondaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOptions() {
    return Column(
      children: [
        _buildSettingTile(
          Icons.settings,
          'Settings',
          'Manage your preferences',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          Icons.notifications,
          'Notifications',
          'Manage notification preferences',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildSettingTile(
          Icons.privacy_tip,
          'Privacy & Security',
          'Control your privacy settings',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacySecurityScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(AppConfig.textSecondaryColor).withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(AppConfig.primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(AppConfig.primaryColor)),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Color(AppConfig.textSecondaryColor),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
