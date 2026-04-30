import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../models/package_model.dart';
import '../../services/auth_service.dart';
import '../../services/package_service.dart';
import '../../widgets/review_dialog.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Map<String, dynamic>> _bookingsWithPackages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = await AuthService.getInstance();
      final travelerId = authService.currentUser?.id;

      if (travelerId == null) {
        throw Exception('User not logged in');
      }

      final packageService = await PackageService.getInstance();
      final bookings = await packageService.getTravelerBookings(travelerId);

      List<Map<String, dynamic>> enrichedBookings = [];
      for (var booking in bookings) {
        final package = await packageService.getPackageById(booking.packageId);
        enrichedBookings.add({
          'booking': booking,
          'package': package,
        });
      }

      if (mounted) {
        setState(() {
          _bookingsWithPackages = enrichedBookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(isDark)
                : _bookingsWithPackages.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildBookingsList(isDark),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(_error ?? 'An error occurred'),
          TextButton(onPressed: _loadBookings, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Your booked packages will appear here.'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookingsWithPackages.length,
      itemBuilder: (context, index) {
        final item = _bookingsWithPackages[index];
        final PackageBooking booking = item['booking'];
        final PackageModel? package = item['package'];

        return _buildBookingCard(booking, package, isDark);
      },
    );
  }

  Widget _buildBookingCard(
      PackageBooking booking, PackageModel? package, bool isDark) {
    final statusColor = _getStatusColor(booking.status);
    final dateStr = DateFormat('MMM dd, yyyy').format(booking.bookingDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    package?.title ?? 'Unknown Package',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(booking.status, statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  'Booked for: $dateStr',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  'Amount: \$${booking.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (booking.status == 'completed') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: booking.reviewSubmitted
                    ? OutlinedButton.icon(
                        onPressed: null, // Disabled
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text('Review Submitted'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _showReviewDialog(booking, package),
                        icon: const Icon(Icons.star_border_purple500_rounded, size: 20),
                        label: const Text('Leave Blockchain Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(AppConfig.primaryColor),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Color(AppConfig.primaryColor);
      default:
        return Colors.orange;
    }
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showReviewDialog(PackageBooking booking, PackageModel? package) {
    if (package == null) return;
    
    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        packageId: package.id!,
        packageName: package.title,
        bookingId: booking.id!,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review successfully added to blockchain!'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload bookings to reflect the updated review status
          _loadBookings();
        },
      ),
    );
  }
}
