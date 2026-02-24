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
      width: MediaQuery.of(context).size.width * 0.8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Elegant Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(AppConfig.primaryColor).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(AppConfig.primaryColor).withOpacity(0.1),
                    child: Icon(Icons.person_rounded, size: 36, color: Color(AppConfig.primaryColor)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TripNexus',
                        style: GoogleFonts.outfit(
                          color: Color(AppConfig.primaryColor),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userRole,
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildModernDrawerItem(
                  context: context,
                  icon: Icons.grid_view_rounded,
                  title: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                  isActive: true,
                ),
                _buildModernDrawerItem(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                  },
                ),
                _buildModernDrawerItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        'SUPPORT',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.grey.shade100, height: 1)),
                    ],
                  ),
                ),
                
                _buildModernDrawerItem(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                  },
                ),
                _buildModernDrawerItem(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  title: 'About TripNexus',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                  },
                ),
              ],
            ),
          ),
          
          // Logout Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive 
                  ? primaryColor.withOpacity(isDark ? 0.15 : 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: isActive 
                      ? primaryColor 
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)), 
                  size: 22
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isActive 
                          ? primaryColor 
                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
