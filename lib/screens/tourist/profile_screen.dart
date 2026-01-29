import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../settings/privacy_security_screen.dart';
import '../settings/notification_settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildStatistics(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 50),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConfig.primaryColor),
            Color(AppConfig.primaryColor).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(AppConfig.primaryColor).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  Text(
                    'My Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _user!.profileImage != null
                        ? NetworkImage(_user!.profileImage!)
                        : null,
                    child: _user!.profileImage == null
                        ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                      if (result == true) {
                        _loadUserProfile();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.camera_alt, color: Color(AppConfig.primaryColor), size: 18),
                    ),
                  ),
                ),
              ],
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
            const SizedBox(height: 4),
            Text(
              _user!.email,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _user!.isVerified ? Icons.verified : Icons.verified_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _user!.isVerified ? 'Verified Account' : 'Not Verified',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(Icons.flight_takeoff, 'Trips', '0'),
          Container(height: 40, width: 1, color: Colors.grey.shade100),
          _buildStatItem(Icons.bookmark, 'Saved', '0'),
          Container(height: 40, width: 1, color: Colors.grey.shade100),
          _buildStatItem(Icons.person_search, 'Advisors', '0'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(AppConfig.primaryColor).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(AppConfig.primaryColor), size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Personal Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.phone_outlined, 'Phone', _user!.phoneNumber),
              _buildDivider(),
              _buildInfoRow(Icons.email_outlined, 'Email', _user!.email),
              if (_user!.country != null) ...[
                _buildDivider(),
                _buildInfoRow(Icons.public, 'Country', _user!.country!),
              ],
              if (_user!.address != null) ...[
                _buildDivider(),
                _buildInfoRow(Icons.location_on_outlined, 'Address', _user!.address!),
              ],
              if (_user!.languages != null && _user!.languages!.isNotEmpty) ...[
                _buildDivider(),
                _buildInfoRow(Icons.translate, 'Languages', _user!.languages!.join(', ')),
              ],
              _buildDivider(),
              _buildInfoRow(
                Icons.calendar_today_outlined,
                'Member Since',
                _formatDate(_user!.createdAt),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Color(AppConfig.textSecondaryColor), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Color(AppConfig.textSecondaryColor),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Color(AppConfig.textPrimaryColor),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 64, endIndent: 20);
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Settings',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _buildActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                  if (result == true) {
                    _loadUserProfile();
                  }
                },
              ),
              _buildDivider(),
              _buildActionButton(
                icon: Icons.security_outlined,
                label: 'Privacy & Security',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacySecurityScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildActionButton(
                icon: Icons.notifications_outlined,
                label: 'Notification Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(AppConfig.primaryColor).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Color(AppConfig.primaryColor), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(AppConfig.textPrimaryColor),
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
