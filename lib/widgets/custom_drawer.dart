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
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final primaryColor = Color(AppConfig.primaryColor);

    return Drawer(
      backgroundColor: backgroundColor,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Dynamic Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [primaryColor, primaryColor.withOpacity(0.85)],
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : primaryColor).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 38, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userRole,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildModernDrawerItem(
                  context: context,
                  icon: Icons.home_rounded,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                  color: const Color(0xFF64B5F6), // Soft Blue
                ),
                _buildModernDrawerItem(
                  context: context,
                  icon: Icons.person_rounded,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  color: const Color(0xFFBA68C8), // Soft Purple
                ),
                _buildModernDrawerItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  color: const Color(0xFFFFB74D), // Soft Orange
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildModernDrawerItem(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                    );
                  },
                  color: const Color(0xFF4DB6AC), // Soft Teal
                ),
                _buildModernDrawerItem(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                  color: const Color(0xFF7986CB), // Soft Indigo
                ),
              ],
            ),
          ),
          
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Color(AppConfig.errorColor).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(AppConfig.errorColor).withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Color(AppConfig.errorColor), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        color: Color(AppConfig.errorColor),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.transparent,
              border: isDark 
                  ? Border.all(color: Colors.white.withOpacity(0.05))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : const Color(0xFF2D3748),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
