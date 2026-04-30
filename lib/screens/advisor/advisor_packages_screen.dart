import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../models/package_model.dart';
import '../../services/package_service.dart';
import '../../services/auth_service.dart';
import 'create_package_screen.dart';

class AdvisorPackagesScreen extends StatefulWidget {
  const AdvisorPackagesScreen({super.key});

  @override
  State<AdvisorPackagesScreen> createState() => _AdvisorPackagesScreenState();
}

class _AdvisorPackagesScreenState extends State<AdvisorPackagesScreen> {
  List<PackageModel> _allPackages = [];
  List<PackageModel> _packages = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, live, draft, archived

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);

    try {
      final authService = await AuthService.getInstance();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final packageService = await PackageService.getInstance();
      final packages = await packageService.getAdvisorPackages(currentUser.id!);

      if (mounted) {
        setState(() {
          _allPackages = packages;
          _packages = packages;
          _isLoading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading packages: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    setState(() {
      switch (_selectedFilter) {
        case 'live':
          _packages = _allPackages.where((p) => p.status == PackageStatus.live).toList();
          break;
        case 'draft':
          _packages = _allPackages.where((p) => p.status == PackageStatus.draft).toList();
          break;
        case 'archived':
          _packages = _allPackages.where((p) => p.status == PackageStatus.archived).toList();
          break;
        default:
          _packages = _allPackages;
      }
    });
  }

  Future<void> _togglePackageStatus(PackageModel package) async {
    try {
      final packageService = await PackageService.getInstance();
      final newStatus = package.status == PackageStatus.live
          ? PackageStatus.draft
          : PackageStatus.live;

      final success = await packageService.updatePackageStatus(package.id!, newStatus);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == PackageStatus.live
                  ? 'Package is now live!'
                  : 'Package moved to draft',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadPackages();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating package: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePackage(PackageModel package) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: const Text('Are you sure you want to delete this package?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final packageService = await PackageService.getInstance();
      final success = await packageService.deletePackage(package.id!);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Package deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPackages();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting package: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToCreatePackage({PackageModel? package}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePackageScreen(package: package),
      ),
    );

    if (result == true) {
      _loadPackages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Packages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPackages,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _packages.isEmpty
                    ? _buildEmptyState()
                    : _buildPackagesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreatePackage(),
        backgroundColor: Color(AppConfig.primaryColor),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Package',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Live', 'live'),
            const SizedBox(width: 8),
            _buildFilterChip('Draft', 'draft'),
            const SizedBox(width: 8),
            _buildFilterChip('Archived', 'archived'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
        _applyFilter();
      },
      backgroundColor: Colors.transparent,
      selectedColor: Color(AppConfig.primaryColor).withOpacity(0.2),
      labelStyle: GoogleFonts.poppins(
        color: isSelected
            ? Color(AppConfig.primaryColor)
            : Color(AppConfig.textSecondaryColor),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Color(AppConfig.textSecondaryColor).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No packages found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first package to get started',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Color(AppConfig.textSecondaryColor).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesList() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: _packages.length,
      itemBuilder: (context, index) {
        final package = _packages[index];
        return _buildPackageCard(package);
      },
    );
  }

  Widget _buildPackageCard(PackageModel package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToCreatePackage(package: package),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(AppConfig.textPrimaryColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          package.destination,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Color(AppConfig.textSecondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(package.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                package.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Color(AppConfig.textSecondaryColor),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.attach_money, '\$${package.price.toStringAsFixed(0)}'),
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.access_time, '${package.duration} days'),
                  const SizedBox(width: 12),
                  _buildInfoChip(Icons.people, '${package.maxTravelers} max'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(
                      package.category,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    backgroundColor: Color(AppConfig.primaryColor).withOpacity(0.1),
                    labelStyle: TextStyle(color: Color(AppConfig.primaryColor)),
                  ),
                  const Spacer(),
                  if (package.totalBookings > 0)
                    Text(
                      '${package.totalBookings} bookings',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Color(AppConfig.textSecondaryColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _togglePackageStatus(package),
                    icon: Icon(
                      package.status == PackageStatus.live
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 20,
                    ),
                    label: Text(
                      package.status == PackageStatus.live
                          ? 'Draft'
                          : 'Live',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _navigateToCreatePackage(package: package),
                    icon: const Icon(Icons.edit, size: 20),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _deletePackage(package),
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    label: Text(
                      'Delete',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PackageStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case PackageStatus.live:
        color = Colors.green;
        text = 'Live';
        break;
      case PackageStatus.draft:
        color = Colors.orange;
        text = 'Draft';
        break;
      case PackageStatus.archived:
        color = Colors.grey;
        text = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Color(AppConfig.textSecondaryColor),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Color(AppConfig.textSecondaryColor),
          ),
        ),
      ],
    );
  }
}
