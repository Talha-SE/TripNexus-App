import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _tripUpdates = true;
  bool _advisorMessages = true;
  bool _bookingConfirmations = true;
  bool _promotions = false;
  bool _priceAlerts = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _weatherNotifications = true;
  bool _newsNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tripUpdates = prefs.getBool('trip_updates') ?? true;
      _advisorMessages = prefs.getBool('advisor_messages') ?? true;
      _bookingConfirmations = prefs.getBool('booking_confirmations') ?? true;
      _promotions = prefs.getBool('promotions') ?? false;
      _priceAlerts = prefs.getBool('price_alerts') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _weatherNotifications = prefs.getBool('weather_notifications') ?? true;
      _newsNotifications = prefs.getBool('news_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trip_updates', _tripUpdates);
    await prefs.setBool('advisor_messages', _advisorMessages);
    await prefs.setBool('booking_confirmations', _bookingConfirmations);
    await prefs.setBool('promotions', _promotions);
    await prefs.setBool('price_alerts', _priceAlerts);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('weather_notifications', _weatherNotifications);
    await prefs.setBool('news_notifications', _newsNotifications);
    await prefs.setBool('push_notifications', _pushNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            icon: Icons.wb_sunny_outlined,
            title: 'Smart Notifications',
            children: [
              _buildSwitchTile(
                title: 'Weather Forecast Notifications',
                subtitle: 'Auto-check weather for your searched locations',
                value: _weatherNotifications,
                onChanged: (value) {
                  setState(() => _weatherNotifications = value);
                  _saveSettings();
                },
              ),
              const Divider(),
              _buildSwitchTile(
                title: 'News Alert Notifications',
                subtitle: 'Get travel news updates for your destinations',
                value: _newsNotifications,
                onChanged: (value) {
                  setState(() => _newsNotifications = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            icon: Icons.notifications_active,
            title: 'Trip Notifications',
            children: [
              _buildSwitchTile(
                title: 'Trip Updates',
                subtitle: 'Get notified about your trip status',
                value: _tripUpdates,
                onChanged: (value) {
                  setState(() => _tripUpdates = value);
                  _saveSettings();
                },
              ),
              const Divider(),
              _buildSwitchTile(
                title: 'Booking Confirmations',
                subtitle: 'Receive booking confirmations',
                value: _bookingConfirmations,
                onChanged: (value) {
                  setState(() => _bookingConfirmations = value);
                  _saveSettings();
                },
              ),
              const Divider(),
              _buildSwitchTile(
                title: 'Price Alerts',
                subtitle: 'Get notified when prices drop',
                value: _priceAlerts,
                onChanged: (value) {
                  setState(() => _priceAlerts = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            icon: Icons.people,
            title: 'Social Notifications',
            children: [
              _buildSwitchTile(
                title: 'Advisor Messages',
                subtitle: 'Get notified when advisors message you',
                value: _advisorMessages,
                onChanged: (value) {
                  setState(() => _advisorMessages = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            icon: Icons.campaign,
            title: 'Marketing',
            children: [
              _buildSwitchTile(
                title: 'Promotions & Offers',
                subtitle: 'Receive special deals and promotions',
                value: _promotions,
                onChanged: (value) {
                  setState(() => _promotions = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            icon: Icons.settings_suggest,
            title: 'Notification Channels',
            children: [
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive notifications on this device',
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() => _pushNotifications = value);
                  _saveSettings();
                },
              ),
              const Divider(),
              _buildSwitchTile(
                title: 'Email Notifications',
                subtitle: 'Receive notifications via email',
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: Color(AppConfig.primaryColor).withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(AppConfig.primaryColor)),
                      const SizedBox(width: 8),
                      Text(
                        'Notification Tips',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(AppConfig.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Important trip updates will always be sent\n'
                    '• You can customize notification sounds in device settings\n'
                    '• Quiet hours: 10 PM - 8 AM (your local time)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Color(AppConfig.textSecondaryColor),
                      height: 1.5,
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
      activeThumbColor: Color(AppConfig.primaryColor),
    );
  }
}
