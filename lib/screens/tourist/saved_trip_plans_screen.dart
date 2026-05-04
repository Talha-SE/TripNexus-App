import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/mongodb_service.dart';
import '../../models/saved_trip_plan_model.dart';
import '../../widgets/trip_plan_view.dart';
import 'ai_trip_planner_screen.dart';

class SavedTripPlansScreen extends StatefulWidget {
  const SavedTripPlansScreen({super.key});

  @override
  State<SavedTripPlansScreen> createState() => _SavedTripPlansScreenState();
}

class _SavedTripPlansScreenState extends State<SavedTripPlansScreen> {
  List<SavedTripPlanModel> _savedPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPlans();
  }

  Future<void> _loadSavedPlans() async {
    setState(() => _isLoading = true);

    try {
      final authService = await AuthService.getInstance();
      final user = authService.currentUser;

      if (user == null) return;

      final mongoService = await MongoDBService.getInstance();
      await mongoService.ensureConnected();
      final collection = mongoService.getSavedTripPlansCollection();
      
      final plans = await collection
          .find({'userId': user.id})
          .toList();
      
      setState(() {
        _savedPlans = plans
            .map((p) => SavedTripPlanModel.fromJson(p))
            .toList()
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trip plans: $e')),
        );
      }
    }
  }

  Future<void> _deletePlan(SavedTripPlanModel plan) async {
    try {
      final mongoService = await MongoDBService.getInstance();
      await mongoService.ensureConnected();
      final collection = mongoService.getSavedTripPlansCollection();
      
      await collection.deleteOne({'_id': plan.id});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip plan deleted')),
        );
        _loadSavedPlans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  void _showPlanDetails(SavedTripPlanModel plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _TripPlanDetailScreen(plan: plan, onDelete: () => _deletePlan(plan)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Saved Trip Plans',
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(AppConfig.primaryColor)),
              ),
            )
          : _savedPlans.isEmpty
              ? _buildEmptyState(isDark)
              : Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadSavedPlans,
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 100, 16, 16),
                      itemCount: _savedPlans.length,
                      itemBuilder: (context, index) {
                        final plan = _savedPlans[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showPlanDetails(plan),
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(AppConfig.primaryColor),
                                                Color(AppConfig.primaryColor).withOpacity(0.7),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(AppConfig.primaryColor).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.map_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                plan.destination,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                                ),
                                              ),
                                              Text(
                                                DateFormat('MMM d, yyyy').format(plan.savedAt),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: isDark ? Colors.white24 : Colors.grey.shade400,
                                            size: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        _buildInfoTag(
                                          icon: Icons.calendar_today_rounded,
                                          label: '${plan.duration} days',
                                          isDark: isDark,
                                          color: Colors.blue,
                                        ),
                                        if (plan.budget != null) ...[
                                          const SizedBox(width: 12),
                                          _buildInfoTag(
                                            icon: Icons.payments_rounded,
                                            label: plan.budget!,
                                            isDark: isDark,
                                            color: Colors.green,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.interests_rounded,
                                            size: 14,
                                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              plan.interests,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Color(AppConfig.primaryColor).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.travel_explore_rounded,
                size: 80,
                color: Color(AppConfig.primaryColor).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No saved trip plans',
              style: GoogleFonts.outfit(
                fontSize: 24,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your personalized AI travel itineraries will appear here once you save them.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AITripPlannerScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: Color(AppConfig.primaryColor).withOpacity(0.4),
                ),
                child: Text(
                  'Generate My First Plan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripPlanDetailScreen extends StatelessWidget {
  final SavedTripPlanModel plan;
  final VoidCallback onDelete;

  const _TripPlanDetailScreen({required this.plan, required this.onDelete});

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: plan.plan)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Itinerary copied to clipboard!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Trip Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
                : [primaryColor, const Color(0xFF1565C0)],
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
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 22),
            onPressed: () => _copyToClipboard(context),
            tooltip: 'Copy itinerary',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Trip Plan'),
                  content: const Text('Are you sure you want to delete this trip plan?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close detail screen
                        onDelete();
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 100, 12, 24),
          child: TripPlanView(
            destination: plan.destination,
            duration: plan.duration,
            interests: plan.interests,
            budget: plan.budget,
            planText: plan.plan,
          ),
        ),
      ),
    );
  }
}
