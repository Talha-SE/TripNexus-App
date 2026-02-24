import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import 'two_factor_auth_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _TwoFASetupSheet extends StatefulWidget {
  final VoidCallback onVerified;

  const _TwoFASetupSheet({required this.onVerified});

  @override
  State<_TwoFASetupSheet> createState() => _TwoFASetupSheetState();
}

class _TwoFASetupSheetState extends State<_TwoFASetupSheet> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  final String _correctCode = "839241"; // Derived from TN-8392-4105

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyCode() async {
    String code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() => _isVerifying = true);
    
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    if (code == _correctCode) {
      if (mounted) {
        Navigator.pop(context);
        widget.onVerified();
      }
    } else {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Invalid verification code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        // Clear fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Verify 2FA Setup',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter the 6-digit code from your authenticator app to complete setup.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          
          // PIN Input Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 45,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                    if (index == 5 && value.isNotEmpty) {
                      _verifyCode();
                    }
                  },
                ),
              );
            }),
          ),
          
          const SizedBox(height: 32),
          
          // QR Code Reference (Small)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code_2_rounded, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Secret Code: TN-8392-4105',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Verify & Enable',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _showProfilePublic = true;
  bool _saveHistory = true;
  bool _twoFactorAuth = false;

  void _show2FASetupDialog() {
    if (_twoFactorAuth) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TwoFactorAuthScreen()),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _TwoFASetupSheet(
          onVerified: () {
            setState(() => _twoFactorAuth = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ 2FA enabled successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [Color(AppConfig.primaryColor), const Color(0xFF1565C0)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 80, 20, 24),
          children: [
            _buildSection(
              icon: Icons.privacy_tip_rounded,
              title: 'Privacy Settings',
              isDark: isDark,
              children: [
                _buildSwitchTile(
                  title: 'Public Profile',
                  subtitle: 'Allow others to view your profile',
                  value: _showProfilePublic,
                  onChanged: (value) => setState(() => _showProfilePublic = value),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  title: 'Save Search History',
                  subtitle: 'Keep record of your searches',
                  value: _saveHistory,
                  onChanged: (value) => setState(() => _saveHistory = value),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              icon: Icons.security_rounded,
              title: 'Security',
              isDark: isDark,
              children: [
                _buildActionTile(
                  icon: Icons.security_rounded,
                  title: 'Two-Factor Authentication',
                  subtitle: 'Add extra security to your account',
                  onTap: () => _show2FASetupDialog(),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildActionTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your password regularly',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password feature coming soon')),
                    );
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildActionTile(
                  icon: Icons.devices_rounded,
                  title: 'Active Sessions',
                  subtitle: 'Manage devices logged into your account',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sessions management coming soon')),
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
          const SizedBox(height: 24),
          _buildSection(
            icon: Icons.description_rounded,
            title: 'Legal',
            isDark: isDark,
            children: [
              _buildActionTile(
                icon: Icons.article_rounded,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {
                  _showInfoDialog(
                    'Privacy Policy',
                    'We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you how we handle your personal data when you use our app.',
                  );
                },
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildActionTile(
                icon: Icons.gavel_rounded,
                title: 'Terms of Service',
                subtitle: 'Read terms and conditions',
                onTap: () {
                  _showInfoDialog(
                    'Terms of Service',
                    'By using TripNexus, you agree to our terms of service. Please read these terms carefully before using our services.',
                  );
                },
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.red.withOpacity(0.1)),
            ),
            color: isDark ? Colors.red.withOpacity(0.05) : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 12),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showDeleteAccountDialog(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade700.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(AppConfig.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Color(AppConfig.primaryColor), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: isDark ? Colors.white38 : Colors.grey.shade600,
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
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? Colors.white60 : Colors.grey.shade600, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: isDark ? Colors.white38 : Colors.grey.shade600,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
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
