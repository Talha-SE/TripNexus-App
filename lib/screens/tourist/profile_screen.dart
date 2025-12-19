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
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildInfoSection(),
          const SizedBox(height: 16),
          _buildStatistics(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(AppConfig.primaryColor),
            Color(AppConfig.secondaryColor),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: _user!.profileImage != null
                        ? ClipOval(
                            child: Image.network(
                              _user!.profileImage!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, size: 60, color: Colors.grey.shade400);
                              },
                            ),
                          )
                        : Icon(Icons.person, size: 60, color: Colors.grey.shade400),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(AppConfig.primaryColor),
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: Color(AppConfig.primaryColor)),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          );
                          if (result == true) {
                            _loadUserProfile();
                          }
                        },
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
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _user!.isVerified ? Icons.verified : Icons.verified_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _user!.isVerified ? 'Verified' : 'Not Verified',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConfig.textPrimaryColor),
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.phone, 'Phone', _user!.phoneNumber),
              const Divider(height: 24),
              _buildInfoRow(Icons.email, 'Email', _user!.email),
              if (_user!.country != null) ...[
                const Divider(height: 24),
                _buildInfoRow(Icons.public, 'Country', _user!.country!),
              ],
              if (_user!.address != null) ...[
                const Divider(height: 24),
                _buildInfoRow(Icons.location_on, 'Address', _user!.address!),
              ],
              if (_user!.languages != null && _user!.languages!.isNotEmpty) ...[
                const Divider(height: 24),
                _buildInfoRow(Icons.language, 'Languages', _user!.languages!.join(', ')),
              ],
              const Divider(height: 24),
              _buildInfoRow(
                Icons.calendar_today,
                'Member Since',
                _formatDate(_user!.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(AppConfig.primaryColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(AppConfig.primaryColor), size: 20),
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
              const SizedBox(height: 4),
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
    );
  }

  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.flight_takeoff, 'Trips', '0'),
              _buildDivider(),
              _buildStatItem(Icons.bookmark, 'Saved', '0'),
              _buildDivider(),
              _buildStatItem(Icons.person_search, 'Advisors', '0'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Color(AppConfig.primaryColor), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
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
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.edit,
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
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.security,
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
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.notifications,
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(AppConfig.primaryColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Color(AppConfig.primaryColor)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(AppConfig.textPrimaryColor),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
