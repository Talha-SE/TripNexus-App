import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _showProfilePublic = true;
  bool _shareLocation = false;
  bool _twoFactorAuth = false;
  bool _saveHistory = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            icon: Icons.privacy_tip,
            title: 'Privacy Settings',
            children: [
              _buildSwitchTile(
                title: 'Public Profile',
                subtitle: 'Allow others to view your profile',
                value: _showProfilePublic,
                onChanged: (value) => setState(() => _showProfilePublic = value),
              ),
              const Divider(),
              _buildSwitchTile(
                title: 'Share Location',
                subtitle: 'Share your location in trip posts',
                value: _shareLocation,
                onChanged: (value) => setState(() => _shareLocation = value),
              ),
              const Divider(),
              _buildSwitchTile(
                title: 'Save Search History',
                subtitle: 'Keep record of your searches',
                value: _saveHistory,
                onChanged: (value) => setState(() => _saveHistory = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            icon: Icons.security,
            title: 'Security',
            children: [
              _buildSwitchTile(
                title: 'Two-Factor Authentication',
                subtitle: 'Add extra security to your account',
                value: _twoFactorAuth,
                onChanged: (value) => setState(() => _twoFactorAuth = value),
              ),
              const Divider(),
              _buildActionTile(
                icon: Icons.lock_reset,
                title: 'Change Password',
                subtitle: 'Update your password regularly',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change password feature coming soon')),
                  );
                },
              ),
              const Divider(),
              _buildActionTile(
                icon: Icons.devices,
                title: 'Active Sessions',
                subtitle: 'Manage devices logged into your account',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sessions management coming soon')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            icon: Icons.description,
            title: 'Legal',
            children: [
              _buildActionTile(
                icon: Icons.article,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {
                  _showInfoDialog(
                    'Privacy Policy',
                    'We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you how we handle your personal data when you use our app.',
                  );
                },
              ),
              const Divider(),
              _buildActionTile(
                icon: Icons.gavel,
                title: 'Terms of Service',
                subtitle: 'Read terms and conditions',
                onTap: () {
                  _showInfoDialog(
                    'Terms of Service',
                    'By using TripNexus, you agree to our terms of service. Please read these terms carefully before using our services.',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Danger Zone',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      _showDeleteAccountDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade700),
                    ),
                    child: const Text('Delete Account'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(AppConfig.primaryColor)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConfig.textPrimaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Color(AppConfig.textSecondaryColor),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Color(AppConfig.primaryColor),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Color(AppConfig.primaryColor)),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
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
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(content, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion feature coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
