import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/mongodb_service.dart';
import '../../models/saved_trip_plan_model.dart';
import '../../widgets/formatted_text.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Trip Plans'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPlans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No saved trip plans',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate AI trip plans and save them here',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSavedPlans,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _savedPlans.length,
                    itemBuilder: (context, index) {
                      final plan = _savedPlans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _showPlanDetails(plan),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Color(AppConfig.primaryColor),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        plan.destination,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(AppConfig.textPrimaryColor),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${plan.duration} days',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (plan.budget != null) ...[
                                      const SizedBox(width: 12),
                                      Icon(Icons.attach_money, size: 14, color: Colors.grey.shade600),
                                      Text(
                                        plan.budget!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.favorite, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        plan.interests,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Saved ${DateFormat('MMM dd, yyyy').format(plan.savedAt)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _TripPlanDetailScreen extends StatelessWidget {
  final SavedTripPlanModel plan;
  final VoidCallback onDelete;

  const _TripPlanDetailScreen({required this.plan, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.destination),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(AppConfig.primaryColor),
                          Color(AppConfig.accentColor),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                plan.destination,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip(Icons.calendar_today, '${plan.duration} days'),
                            if (plan.budget != null) ...[
                              const SizedBox(width: 8),
                              _buildInfoChip(Icons.attach_money, plan.budget!),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoChip(Icons.favorite, plan.interests),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FormattedText(
                    text: plan.plan,
                    fontSize: 14,
                    textColor: Color(AppConfig.textPrimaryColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Saved ${DateFormat('MMMM dd, yyyy • hh:mm a').format(plan.savedAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(AppConfig.textSecondaryColor),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete Trip Plan'),
                    content: const Text('Are you sure you want to delete this saved trip plan?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pop(context);
                          onDelete();
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Color(AppConfig.errorColor)),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConfig.errorColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
