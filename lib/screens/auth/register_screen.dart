import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../advisor/advisor_dashboard.dart';
import '../tourist/tourist_dashboard.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  UserRole? _selectedRole;
  final List<String> _selectedLanguages = [];
  final List<String> _availableLanguages = const [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Arabic',
    'Chinese',
    'Japanese',
    'Hindi',
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _descriptionController.dispose();
    _expertiseController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  InputDecoration _dec(
    String label,
    IconData icon, {
    Widget? suffix,
    String? hint,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 13),
    prefixIcon: Icon(icon, color: const Color(0xFF0A57A6), size: 21),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.92),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Color(AppConfig.primaryColor), width: 1.6),
    ),
  );

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a role')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authService = await AuthService.getInstance();
      final result = await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: _selectedRole!,
        businessName: _businessNameController.text.trim().isEmpty
            ? null
            : _businessNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        expertise: _expertiseController.text.trim().isEmpty
            ? null
            : _expertiseController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        languages: _selectedLanguages.isEmpty ? null : _selectedLanguages,
      );
      if (!mounted) return;
      if (result['success']) {
        final user = result['user'] as UserModel;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Color(AppConfig.accentColor),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => user.isTourist
                ? const TouristDashboard()
                : const AdvisorDashboard(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Color(AppConfig.errorColor),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Color(AppConfig.errorColor),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _roleCard(
    UserRole role,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? 0.9 : 0.35),
            width: selected ? 1.8 : 1.1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF052E66)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF0A57A6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11.8,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  TextStyle _stepHeadingStyle() {
    return GoogleFonts.poppins(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: 0.2,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _stepBody() {
    if (_currentStep == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Select Your Role', style: _stepHeadingStyle()),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to use TripNexus',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.96),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _roleCard(
            UserRole.tourist,
            Icons.explore,
            'Tourist',
            'Plan trips and discover places',
          ),
          const SizedBox(height: 10),
          _roleCard(
            UserRole.advisorIndividual,
            Icons.person_outline,
            'Travel Advisor (Individual)',
            'Offer travel guidance as a professional',
          ),
          const SizedBox(height: 10),
          _roleCard(
            UserRole.advisorAgency,
            Icons.business,
            'Travel Agency',
            'Provide services as an agency',
          ),
        ],
      );
    }
    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Basic Information', style: _stepHeadingStyle()),
          const SizedBox(height: 14),
          TextFormField(
            controller: _fullNameController,
            decoration: _dec('Full Name', Icons.person_outline),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter your full name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec('Email', Icons.email_outlined),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _dec('Phone Number', Icons.phone_outlined),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Please enter your phone number'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _dec(
              'Password',
              Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: _dec(
              'Confirm Password',
              Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
            validator: (v) => (v != _passwordController.text)
                ? 'Passwords do not match'
                : null,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _selectedRole == UserRole.advisorAgency
              ? 'Agency Information'
              : 'Professional Information',
          style: _stepHeadingStyle(),
        ),
        const SizedBox(height: 14),
        if (_selectedRole == UserRole.advisorAgency) ...[
          TextFormField(
            controller: _businessNameController,
            decoration: _dec('Agency Name', Icons.business),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Please enter your agency name'
                : null,
          ),
          const SizedBox(height: 12),
        ],
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: _dec(
            'Description',
            Icons.description_outlined,
            hint: 'Tell us about your services...',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _expertiseController,
          decoration: _dec(
            'Expertise',
            Icons.star_outline,
            hint: 'Adventure, Luxury, etc.',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          decoration: _dec('Address', Icons.location_on_outlined),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _countryController,
          decoration: _dec('Country', Icons.public),
        ),
        const SizedBox(height: 12),
        Text(
          'Languages Spoken',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableLanguages.map((l) {
            final selected = _selectedLanguages.contains(l);
            return FilterChip(
              label: Text(
                l,
                style: GoogleFonts.poppins(
                  color: selected ? const Color(0xFF052E66) : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: selected,
              onSelected: (v) => setState(
                () => v
                    ? _selectedLanguages.add(l)
                    : _selectedLanguages.remove(l),
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              selectedColor: Colors.white,
              checkmarkColor: const Color(0xFF052E66),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final totalSteps = _selectedRole == UserRole.tourist ? 2 : 3;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF042A5C),
                  Color(0xFF0C5FB8),
                  Color(0xFF2C8DE0),
                ],
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            right: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8FD9FF).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                    child: Row(
                      children: List.generate(
                        totalSteps,
                        (i) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: i < totalSteps - 1 ? 8 : 0,
                            ),
                            height: 7,
                            decoration: BoxDecoration(
                              color: i <= _currentStep
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Center(
                        child: SizedBox(
                          width: size.width * 0.95,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white.withValues(alpha: 0.24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.38),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 26,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _stepBody(),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        if (_currentStep > 0)
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => setState(
                                                () => _currentStep--,
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                side: BorderSide(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.75),
                                                  width: 1.4,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              child: Text(
                                                'Back',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (_currentStep > 0)
                                          const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    if (_currentStep == 0) {
                                                      if (_selectedRole ==
                                                          null) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Please select a role',
                                                            ),
                                                          ),
                                                        );
                                                        return;
                                                      }
                                                      setState(
                                                        () => _currentStep++,
                                                      );
                                                    } else if (_currentStep ==
                                                        1) {
                                                      if (_formKey.currentState!
                                                          .validate()) {
                                                        if (_selectedRole ==
                                                            UserRole.tourist) {
                                                          _handleRegister();
                                                        } else {
                                                          setState(
                                                            () =>
                                                                _currentStep++,
                                                          );
                                                        }
                                                      }
                                                    } else {
                                                      _handleRegister();
                                                    }
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF052C63,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : Text(
                                                    _currentStep == 0
                                                        ? 'Next'
                                                        : (_currentStep == 1 &&
                                                                  _selectedRole ==
                                                                      UserRole
                                                                          .tourist) ||
                                                              _currentStep == 2
                                                        ? 'Sign Up'
                                                        : 'Next',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 15.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account?',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withValues(
                                              alpha: 0.92,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const LoginScreen(),
                                                ),
                                              ),
                                          child: Text(
                                            'Sign In',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
}
