import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../screens/tourist/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/help_support_screen.dart';
import '../screens/settings/about_screen.dart';

class CustomDrawer extends StatelessWidget {
  final String userRole;
  final VoidCallback onLogout;

  const CustomDrawer({
    Key? key,
    required this.userRole,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(AppConfig.primaryColor),
                  Color(AppConfig.secondaryColor),
                ],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      'Welcome!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      userRole,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: onLogout,
                  textColor: Color(AppConfig.errorColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey.shade700),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: textColor ?? Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
