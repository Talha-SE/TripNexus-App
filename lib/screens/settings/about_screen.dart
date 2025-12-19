import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLogoSection(),
          const SizedBox(height: 32),
          _buildInfoCard(
            'Version',
            '1.0.0',
            Icons.info_outline,
          ),
          _buildInfoCard(
            'Build Number',
            '100',
            Icons.build_outlined,
          ),
          _buildInfoCard(
            'Last Updated',
            'December 2025',
            Icons.update_outlined,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('About TripNexus'),
          const SizedBox(height: 12),
          _buildDescriptionCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Features'),
          const SizedBox(height: 12),
          _buildFeatureItem(Icons.map_outlined, 'AI-Powered Trip Planning'),
          _buildFeatureItem(Icons.camera_alt_outlined, 'Landmark Scanner'),
          _buildFeatureItem(Icons.cloud_outlined, 'Weather Forecasts'),
          _buildFeatureItem(Icons.person_outline, 'Expert Advisors'),
          _buildFeatureItem(Icons.bookmark_outline, 'Save & Share Trips'),
          const SizedBox(height: 24),
          _buildSectionTitle('Legal'),
          const SizedBox(height: 12),
          _buildLegalTile('Terms of Service', () {}),
          _buildLegalTile('Privacy Policy', () {}),
          _buildLegalTile('Open Source Licenses', () {}),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2025 TripNexus. All rights reserved.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Color(AppConfig.textSecondaryColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(AppConfig.primaryColor),
            Color(AppConfig.accentColor),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.explore,
              size: 64,
              color: Color(AppConfig.primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'TripNexus',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Smart Travel Companion',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(AppConfig.primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(AppConfig.primaryColor)),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(AppConfig.textPrimaryColor),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'TripNexus is your ultimate travel companion, powered by AI to help you plan perfect trips, discover landmarks, check weather forecasts, and connect with expert advisors. Explore the world with confidence and ease.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Color(AppConfig.textSecondaryColor),
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(AppConfig.primaryColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Color(AppConfig.primaryColor)),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalTile(String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
