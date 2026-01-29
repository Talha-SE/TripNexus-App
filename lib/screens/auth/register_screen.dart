import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../tourist/tourist_dashboard.dart';
import '../advisor/advisor_dashboard.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
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
  final List<String> _availableLanguages = [
    'English', 'Spanish', 'French', 'German', 'Italian', 
    'Portuguese', 'Arabic', 'Chinese', 'Japanese', 'Hindi'
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
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

        // Navigate based on user role
        if (user.isTourist) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TouristDashboard(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdvisorDashboard(),
            ),
          );
        }
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

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Your Role',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(AppConfig.textPrimaryColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how you want to use TripNexus',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Color(AppConfig.textSecondaryColor),
          ),
        ),
        const SizedBox(height: 24),
        _buildRoleCard(
          role: UserRole.tourist,
          icon: Icons.explore,
          title: 'Tourist',
          description: 'Plan trips, discover landmarks, and connect with advisors',
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          role: UserRole.advisorIndividual,
          icon: Icons.person_outline,
          title: 'Travel Advisor (Individual)',
          description: 'Offer personalized travel guidance as an independent advisor',
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          role: UserRole.advisorAgency,
          icon: Icons.business,
          title: 'Travel Agency',
          description: 'Provide comprehensive travel services as an agency',
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedRole == role;
    
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Color(AppConfig.primaryColor).withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected 
                ? Color(AppConfig.primaryColor)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Color(AppConfig.primaryColor)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? Color(AppConfig.primaryColor)
                          : Color(AppConfig.textPrimaryColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(AppConfig.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Color(AppConfig.primaryColor),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Basic Information',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(AppConfig.textPrimaryColor),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdvisorInfo() {
    if (_selectedRole == UserRole.tourist) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _selectedRole == UserRole.advisorAgency 
              ? 'Agency Information' 
              : 'Professional Information',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(AppConfig.textPrimaryColor),
          ),
        ),
        const SizedBox(height: 24),
        if (_selectedRole == UserRole.advisorAgency)
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Agency Name',
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              if (_selectedRole == UserRole.advisorAgency && 
                  (value == null || value.isEmpty)) {
                return 'Please enter your agency name';
              }
              return null;
            },
          ),
        if (_selectedRole == UserRole.advisorAgency)
          const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            prefixIcon: Icon(Icons.description_outlined),
            hintText: 'Tell us about your services...',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _expertiseController,
          decoration: const InputDecoration(
            labelText: 'Expertise',
            prefixIcon: Icon(Icons.star_outline),
            hintText: 'e.g., Adventure Travel, Luxury Tours',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _countryController,
          decoration: const InputDecoration(
            labelText: 'Country',
            prefixIcon: Icon(Icons.public),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Languages Spoken',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(AppConfig.textPrimaryColor),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableLanguages.map((language) {
            final isSelected = _selectedLanguages.contains(language);
            return FilterChip(
              label: Text(language),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLanguages.add(language);
                  } else {
                    _selectedLanguages.remove(language);
                  }
                });
              },
              selectedColor: Color(AppConfig.primaryColor).withValues(alpha: 0.2),
              checkmarkColor: Color(AppConfig.primaryColor),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(AppConfig.primaryColor),
                  Color(0xFF1565C0),
                ],
              ),
            ),
          ),
          
          // Decorative Shapes
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Progress Indicator
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Row(
                      children: List.generate(
                        _selectedRole == UserRole.tourist ? 2 : 3,
                        (index) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: index < (_selectedRole == UserRole.tourist ? 1 : 2) ? 8 : 0),
                            height: 6,
                            decoration: BoxDecoration(
                              color: index <= _currentStep 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                if (index <= _currentStep)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (_currentStep == 0) _buildRoleSelection(),
                                  if (_currentStep == 1) _buildBasicInfo(),
                                  if (_currentStep == 2 && _selectedRole != UserRole.tourist) 
                                    _buildAdvisorInfo(),
                                  const SizedBox(height: 32),
                                  Row(
                                    children: [
                                      if (_currentStep > 0)
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setState(() => _currentStep--);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Color(AppConfig.primaryColor),
                                              side: BorderSide(color: Color(AppConfig.primaryColor)),
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text('Back'),
                                          ),
                                        ),
                                      if (_currentStep > 0) const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : () {
                                            if (_currentStep == 0) {
                                              if (_selectedRole == null) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Please select a role')),
                                                );
                                                return;
                                              }
                                              setState(() => _currentStep++);
                                            } else if (_currentStep == 1) {
                                              if (_formKey.currentState!.validate()) {
                                                if (_selectedRole == UserRole.tourist) {
                                                  _handleRegister();
                                                } else {
                                                  setState(() => _currentStep++);
                                                }
                                              }
                                            } else {
                                              _handleRegister();
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(AppConfig.primaryColor),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            elevation: 5,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Text(
                                                  _currentStep == 0 
                                                      ? 'Next'
                                                      : (_currentStep == 1 && _selectedRole == UserRole.tourist)
                                                          ? 'Sign Up'
                                                          : (_currentStep == 2)
                                                              ? 'Sign Up'
                                                              : 'Next',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: GoogleFonts.poppins(
                                          color: Color(AppConfig.textSecondaryColor),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const LoginScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Login',
                                          style: GoogleFonts.poppins(
                                            color: Color(AppConfig.primaryColor),
                                            fontWeight: FontWeight.w600,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
