import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../utils/app_theme.dart';
import 'privacy_security_screen.dart';
import 'two_factor_auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _weatherNotifications = true;
  bool _tripReminders = true;
  bool _emailNotifications = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weatherNotifications = prefs.getBool('weather_notifications') ?? true;
      _tripReminders = prefs.getBool('trip_reminders') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weather_notifications', _weatherNotifications);
    await prefs.setBool('trip_reminders', _tripReminders);
    await prefs.setBool('email_notifications', _emailNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.cloud_outlined,
            title: 'Weather Forecast Notifications',
            subtitle: 'Get hourly weather updates',
            value: _weatherNotifications,
            onChanged: (value) {
              setState(() => _weatherNotifications = value);
              _saveSettings();
            },
          ),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Trip Reminders',
            subtitle: 'Reminders for upcoming trips',
            value: _tripReminders,
            onChanged: (value) {
              setState(() => _tripReminders = value);
              _saveSettings();
            },
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            subtitle: 'Receive updates via email',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
              _saveSettings();
            },
          ),
          const Divider(height: 32),
          _buildSectionHeader('Account'),
          _buildNavigationTile(
            icon: Icons.lock_outline,
            title: 'Privacy & Security',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySecurityScreen(),
                ),
              );
            },
          ),
          _buildNavigationTile(
            icon: Icons.security_rounded,
            title: 'Two-Factor Authentication',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TwoFactorAuthScreen(),
                ),
              );
            },
          ),
          _buildNavigationTile(
            icon: Icons.person_outline,
            title: 'Account Settings',
            onTap: () {},
          ),
          const Divider(height: 32),
          _buildSectionHeader('App'),
          _buildNavigationTile(
            icon: Icons.language,
            title: 'Language',
            trailing: 'English',
            onTap: () {},
          ),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Theme',
            subtitle: 'Switch between light and dark',
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              ThemeController.setThemeMode(value);
            },
          ),
          _buildNavigationTile(
            icon: Icons.storage_outlined,
            title: 'Clear Cache',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('weather_search_history');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(AppConfig.primaryColor),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(AppConfig.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Color(AppConfig.primaryColor)),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Color(AppConfig.textSecondaryColor),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Color(AppConfig.primaryColor),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(AppConfig.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Color(AppConfig.primaryColor)),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: trailing != null
          ? Text(
              trailing,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Color(AppConfig.textSecondaryColor),
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}


