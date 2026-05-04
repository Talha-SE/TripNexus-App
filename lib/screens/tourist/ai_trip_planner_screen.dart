import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../config/app_config.dart';
import '../../services/mistral_service.dart';
import '../../services/mongodb_service.dart';
import '../../services/auth_service.dart';
import '../../models/saved_trip_plan_model.dart';
import '../../widgets/trip_plan_view.dart';

class AITripPlannerScreen extends StatefulWidget {
  const AITripPlannerScreen({super.key});

  @override
  State<AITripPlannerScreen> createState() => _AITripPlannerScreenState();
}

class _AITripPlannerScreenState extends State<AITripPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _interestsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();
  
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _generatedPlan;

  @override
  void dispose() {
    _destinationController.dispose();
    _interestsController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _generateTripPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _generatedPlan = null;
    });

    try {
      final mistral = MistralService.getInstance();
      final result = await mistral.generateTripPlan(
        destination: _destinationController.text.trim(),
        duration: int.parse(_durationController.text),
        interests: _interestsController.text.trim(),
        budget: _budgetController.text.trim().isEmpty ? null : _budgetController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          if (result['success']) {
            _generatedPlan = result['plan'];
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to generate trip plan'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveTripPlan() async {
    if (_generatedPlan == null) return;

    setState(() => _isSaving = true);

    try {
      final authService = await AuthService.getInstance();
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final mongoService = await MongoDBService.getInstance();
      await mongoService.ensureConnected();
      final collection = mongoService.getSavedTripPlansCollection();

      final savedPlan = SavedTripPlanModel(
        userId: user.id!,
        destination: _destinationController.text.trim(),
        duration: int.parse(_durationController.text),
        interests: _interestsController.text.trim(),
        budget: _budgetController.text.trim().isEmpty ? null : _budgetController.text.trim(),
        plan: _generatedPlan!,
      );

      await collection.insertOne(savedPlan.toJson());

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trip plan saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving trip plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'AI Trip Planner',
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
        actions: [
          if (_generatedPlan != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () => setState(() => _generatedPlan = null),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background matching the Dashboard and Landmark Scanner
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
          ),
          
          _generatedPlan == null ? _buildInputForm() : _buildPlanView(),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 10, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 80), // Space for AppBar
            // Compact Hero Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 32,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Trip Planner',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Let AI create your dream itinerary',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Input Fields with refined styling
            _buildInputField(
              controller: _destinationController,
              label: 'Where do you want to go?',
              hint: 'e.g., Paris, France',
              icon: Icons.location_on_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a destination';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _durationController,
              label: 'How many days?',
              hint: 'e.g., 7',
              icon: Icons.calendar_today_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter duration';
                }
                final days = int.tryParse(value);
                if (days == null || days < 1 || days > 30) {
                  return 'Enter a valid duration (1-30 days)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _interestsController,
              label: 'What are your interests?',
              hint: 'e.g., History, Food, Adventure',
              icon: Icons.favorite_rounded,
              maxLines: 1,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your interests';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _budgetController,
              label: 'Budget (Optional)',
              hint: 'e.g., \$2000, Mid-range',
              icon: Icons.payments_rounded,
            ),
            const SizedBox(height: 32),
            
            // Generate Button or Loading State
            _isGenerating
                ? _buildGeneratingState()
                : ElevatedButton(
                    onPressed: _generateTripPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: primaryColor.withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded),
                        const SizedBox(width: 12),
                        Text(
                          'Generate Trip Plan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SpinKitThreeBounce(
            color: theme.colorScheme.primary,
            size: 30,
          ),
          const SizedBox(height: 16),
          Text(
            'Creating your perfect itinerary...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take 10-30 seconds',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white38 : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: isDark ? Colors.white : theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: isDark ? Colors.white38 : Colors.grey.shade500,
          fontSize: 14,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 22),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
      ),
    );
  }

  Widget _buildPlanView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80), // Space for AppBar
                // Success Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Itinerary Ready',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TripPlanView(
                  destination: _destinationController.text.trim(),
                  duration: int.tryParse(_durationController.text) ?? 0,
                  interests: _interestsController.text.trim(),
                  budget: _budgetController.text.trim().isEmpty ? null : _budgetController.text.trim(),
                  planText: _generatedPlan!,
                ),
                const SizedBox(height: 100), // Space for bottom buttons
              ],
            ),
          ),
        ),
        
        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTripPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Plan',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent,
                  ),
                ),
                child: IconButton(
                  onPressed: () => setState(() => _generatedPlan = null),
                  icon: Icon(
                    Icons.add_rounded,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
