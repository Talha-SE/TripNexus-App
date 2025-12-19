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
  const TripsListScreen({Key? key}) : super(key: key);

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
      appBar: AppBar(
        title: const Text('My Trips'),
      ),
      floatingActionButton: Column(
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
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _isFabMenuOpen ? 0.125 : 0,
              child: Icon(_isFabMenuOpen ? Icons.close : Icons.add),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.luggage, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No trips yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start planning your next adventure!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            // Navigate to trip details
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        trip.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(trip.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        trip.status.toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(trip.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      trip.destination,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (trip.budget != null) ...[
                                      Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                                      Text(
                                        trip.budget!.toStringAsFixed(0),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (trip.isEcoFriendly) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.eco, size: 16, color: Color(AppConfig.accentColor)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Eco-Friendly',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Color(AppConfig.accentColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Trip'),
                                            content: const Text('Are you sure you want to delete this trip?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
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
                                                  style: TextStyle(color: Color(AppConfig.errorColor)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.delete, size: 16, color: Color(AppConfig.errorColor)),
                                      label: Text('Delete', style: TextStyle(color: Color(AppConfig.errorColor))),
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
