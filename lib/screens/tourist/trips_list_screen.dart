import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../models/trip_model.dart';
import '../../services/auth_service.dart';
import '../../services/mongodb_service.dart';
import 'create_trip_screen.dart';
import 'ai_trip_planner_screen.dart';

class TripsListScreen extends StatefulWidget {
  const TripsListScreen({super.key});

  @override
  State<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  List<TripModel> _trips = [];
  bool _isLoading = true;
  bool _isFabMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);

    try {
      final authService = await AuthService.getInstance();
      final user = authService.currentUser;

      if (user == null) return;

      final mongoService = await MongoDBService.getInstance();
      final tripsCollection = mongoService.getTripsCollection();
      
      final trips = await tripsCollection.find({'userId': user.id}).toList();
      
      setState(() {
        _trips = trips.map((trip) => TripModel.fromJson(trip)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trips: $e')),
        );
      }
    }
  }

  Future<void> _deleteTrip(String tripId) async {
    try {
      final mongoService = await MongoDBService.getInstance();
      final tripsCollection = mongoService.getTripsCollection();
      
      await tripsCollection.deleteOne({'_id': tripId});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip deleted successfully')),
        );
        _loadTrips();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting trip: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planned':
        return Colors.blue;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'My Trips',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.sort_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Color(AppConfig.primaryColor), const Color(0xFF1565C0)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Move FAB above the floating nav bar
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_isFabMenuOpen) ...[
              _buildFabOption(
                icon: Icons.auto_awesome,
                label: 'AI Trip Planner',
                color: Color(AppConfig.accentColor),
                onPressed: () async {
                  setState(() => _isFabMenuOpen = false);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AITripPlannerScreen()),
                  );
                  if (result == true) {
                    _loadTrips();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildFabOption(
                icon: Icons.add,
                label: 'Manual Trip',
                color: Color(AppConfig.primaryColor),
                onPressed: () async {
                  setState(() => _isFabMenuOpen = false);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateTripScreen()),
                  );
                  if (result == true) {
                    _loadTrips();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            FloatingActionButton(
              onPressed: () {
                setState(() => _isFabMenuOpen = !_isFabMenuOpen);
              },
              backgroundColor: Color(AppConfig.primaryColor),
              foregroundColor: Colors.white,
              elevation: 4,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: _isFabMenuOpen ? 0.125 : 0,
                child: Icon(_isFabMenuOpen ? Icons.close : Icons.add),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(AppConfig.primaryColor)),
                ),
              )
            : _trips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Color(AppConfig.primaryColor).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.luggage, 
                            size: 64, 
                            color: Color(AppConfig.primaryColor).withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No trips yet',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Color(AppConfig.textPrimaryColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start planning your next adventure!',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white60
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTrips,
                    color: Color(AppConfig.primaryColor),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 100), // Top padding for AppBar
                      itemCount: _trips.length,
                      itemBuilder: (context, index) {
                        final trip = _trips[index];
                        return _buildTripCard(trip);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            // Navigate to trip details
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image / Header
              Stack(
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(AppConfig.primaryColor),
                          Color(AppConfig.primaryColor).withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.flight_takeoff,
                        size: 48,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(trip.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            trip.status.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.title,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(width: 4),
                            Text(
                              trip.destination,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (trip.budget != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1, 
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1)
                  ),
                ),
                
              // Trip Details Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildInfoItem(
                          Icons.calendar_today_rounded,
                          'Date',
                          '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd').format(trip.endDate)}',
                        ),
                        const Spacer(),
                        _buildInfoItem(
                          Icons.monetization_on_outlined,
                          'Budget',
                          '\$${trip.budget!.toStringAsFixed(0)}',
                          isRightAligned: true,
                        ),
                      ],
                    ),
                    if (trip.isEcoFriendly) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(isDark ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withOpacity(isDark ? 0.3 : 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.eco_rounded, size: 20, color: Colors.green.shade400),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Eco-Friendly Trip',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: isDark ? Colors.green.shade300 : Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.edit_note_rounded, color: isDark ? Colors.white60 : Colors.grey[600], size: 22),
                          tooltip: 'Edit Trip',
                          splashRadius: 24,
                        ),
                        IconButton(
                          onPressed: () {
                           _confirmDeleteTrip(trip);
                          },
                          icon: Icon(Icons.delete_outline_rounded, color: Color(AppConfig.errorColor), size: 22),
                          tooltip: 'Delete Trip',
                          splashRadius: 24,
                        ),
                      ],
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
  
  void _confirmDeleteTrip(TripModel trip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'Delete Trip',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${trip.title}"?',
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (trip.id != null) {
                _deleteTrip(trip.id!);
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Color(AppConfig.errorColor),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {bool isRightAligned = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.white60 : Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Color(AppConfig.textPrimaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(icon),
        ),
      ],
    );
  }
}
