

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Frequently Asked Questions'),
          const SizedBox(height: 12),
          _buildFAQItem(
            question: 'How do I plan a trip?',
            answer:
                'You can plan a trip by going to the Trips tab and clicking on "Create New Trip". Follow the step-by-step process to create your perfect itinerary.',
          ),
          _buildFAQItem(
            question: 'How does the landmark scanner work?',
            answer:
                'Use the landmark scanner to identify famous landmarks by taking a photo. Our AI will provide detailed information about the landmark.',
          ),
          _buildFAQItem(
            question: 'How do I enable weather notifications?',
            answer:
                'Go to Settings > Notifications and enable "Weather Forecast Notifications" to receive hourly weather updates for your saved cities.',
          ),
          _buildFAQItem(
            question: 'Can I save multiple weather locations?',
            answer:
                'Yes! You can save up to 3 cities as tabs in the Weather screen. They will automatically update every hour.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Contact Us'),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@tripnexus.com',
            onTap: () {},
          ),
          _buildContactCard(
            icon: Icons.chat_bubble_outline,
            title: 'Live Chat',
            subtitle: 'Available 24/7',
            onTap: () {},
          ),
          _buildContactCard(
            icon: Icons.phone_outlined,
            title: 'Phone Support',
            subtitle: '+1 (800) 123-4567',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(AppConfig.primaryColor),
            Color(AppConfig.accentColor),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.support_agent, size: 64, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            'How can we help you?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We\'re here to assist you 24/7',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
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

  Widget _buildFAQItem({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Color(AppConfig.textSecondaryColor),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
