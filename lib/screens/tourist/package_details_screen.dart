import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import '../../services/package_service.dart';
import '../../services/auth_service.dart';
import 'package_chat_screen.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String packageId;

  const PackageDetailsScreen({super.key, required this.packageId});

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  PackageModel? _package;
  UserModel? _advisor;
  bool _isLoading = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadPackageDetails();
  }

  Future<void> _loadPackageDetails() async {
    setState(() => _isLoading = true);

    try {
      final packageService = await PackageService.getInstance();
      final data = await packageService.getPackageWithAdvisorInfo(widget.packageId);

      if (data != null && mounted) {
        setState(() {
          _package = data['package'] as PackageModel;
          _advisor = data['advisor'] as UserModel?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading package: $e')),
        );
      }
    }
  }

  Future<void> _bookPackage() async {
    final authService = await AuthService.getInstance();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book this package')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text(
          'Book "${_package!.title}" for \$${_package!.price.toStringAsFixed(0)}?\n\nPayment will be done in cash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConfig.primaryColor),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBooking = true);

    try {
      final packageService = await PackageService.getInstance();
      final booking = PackageBooking(
        packageId: widget.packageId,
        travelerId: currentUser.id!,
        advisorId: _package!.advisorId,
        bookingDate: DateTime.now(),
        amount: _package!.price,
        paymentMethod: 'cash',
      );

      final bookingId = await packageService.createBooking(booking);

      if (bookingId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking successful! The advisor will contact you soon.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking package: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  void _openChat() {
    final authService = AuthService.getInstance();
    authService.then((auth) {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to message the advisor')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PackageChatScreen(
            packageId: widget.packageId,
            advisor: _advisor!,
            package: _package!,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_package == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Package not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(AppConfig.primaryColor).withOpacity(0.7),
                      Color(AppConfig.primaryColor),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.landscape,
                    size: 100,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPackageHeader(),
                const Divider(height: 32),
                _buildAdvisorSection(),
                const Divider(height: 32),
                _buildPackageDetails(),
                const Divider(height: 32),
                _buildIncludesExcludes(),
                const Divider(height: 32),
                _buildItinerary(),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomActions(),
    );
  }

  Widget _buildPackageHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                label: Text(
                  _package!.category,
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                backgroundColor: Color(AppConfig.primaryColor).withOpacity(0.1),
                labelStyle: TextStyle(color: Color(AppConfig.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _package!.title,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: Color(AppConfig.textSecondaryColor),
              ),
              const SizedBox(width: 4),
              Text(
                _package!.destination,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Color(AppConfig.textSecondaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoCard(Icons.access_time, '${_package!.duration}', 'Days'),
              const SizedBox(width: 12),
              _buildInfoCard(Icons.people, '${_package!.maxTravelers}', 'Max Travelers'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(AppConfig.primaryColor).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(AppConfig.primaryColor).withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(AppConfig.primaryColor), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
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
        ),
      ),
    );
  }

  Widget _buildAdvisorSection() {
    if (_advisor == null) return const SizedBox();

    final isIndividual = _advisor!.role == UserRole.advisorIndividual;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Advisor',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(AppConfig.primaryColor).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(AppConfig.primaryColor).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Color(AppConfig.primaryColor),
                  child: Text(
                    _advisor!.fullName[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _advisor!.fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(AppConfig.textPrimaryColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isIndividual ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isIndividual ? 'Individual Advisor' : 'Agency Advisor',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isIndividual ? Colors.blue : Colors.purple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 18,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_advisor!.rating?.toStringAsFixed(1) ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(AppConfig.textPrimaryColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.bookmark,
                            size: 18,
                            color: Color(AppConfig.textSecondaryColor),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_advisor!.totalBookings ?? 0} bookings',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Color(AppConfig.textSecondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_advisor!.bio != null && _advisor!.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _advisor!.bio!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(AppConfig.textSecondaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Package',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _package!.description,
            style: GoogleFonts.poppins(
              fontSize: 15,
              height: 1.6,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludesExcludes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_package!.includes.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Includes',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._package!.includes.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Color(AppConfig.textSecondaryColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          if (_package!.includes.isNotEmpty && _package!.excludes.isNotEmpty)
            const SizedBox(width: 16),
          if (_package!.excludes.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Excludes',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._package!.excludes.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.cancel, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Color(AppConfig.textSecondaryColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItinerary() {
    if (_package!.itinerary.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itinerary',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 16),
          ..._package!.itinerary.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(AppConfig.primaryColor),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Color(AppConfig.textSecondaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Color(AppConfig.textSecondaryColor),
                  ),
                ),
                Text(
                  '\$${_package!.price.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConfig.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.message),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Color(AppConfig.primaryColor)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isBooking ? null : _bookPackage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Color(AppConfig.primaryColor),
                ),
                child: _isBooking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Book Now',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
