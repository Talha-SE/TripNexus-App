import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/mongodb_service.dart';

class AdvisorsSearchScreen extends StatefulWidget {
  const AdvisorsSearchScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorsSearchScreen> createState() => _AdvisorsSearchScreenState();
}

class _AdvisorsSearchScreenState extends State<AdvisorsSearchScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _advisors = [];
  List<UserModel> _filteredAdvisors = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, individual, agency
  String _selectedSort = 'name'; // name, rating, experience

  @override
  void initState() {
    super.initState();
    _loadAdvisors();
  }

  Future<void> _loadAdvisors() async {
    setState(() => _isLoading = true);

    try {
      final db = await MongoDBService.getInstance();
      final usersCollection = db.getUsersCollection();

      final advisors = await usersCollection.find({
        'role': {'\$in': ['advisor_individual', 'advisor_agency']}
      }).toList();

      if (mounted) {
        setState(() {
          _advisors = advisors.map((doc) => UserModel.fromJson(doc)).toList();
          _filteredAdvisors = _advisors;
          _isLoading = false;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading advisors: $e')),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    List<UserModel> filtered = _advisors;

    // Apply search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((advisor) {
        return advisor.fullName.toLowerCase().contains(query) ||
            (advisor.expertise?.toLowerCase().contains(query) ?? false) ||
            (advisor.address?.toLowerCase().contains(query) ?? false) ||
            (advisor.country?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply role filter
    if (_selectedFilter == 'individual') {
      filtered = filtered.where((a) => a.role == UserRole.advisorIndividual).toList();
    } else if (_selectedFilter == 'agency') {
      filtered = filtered.where((a) => a.role == UserRole.advisorAgency).toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'name':
        filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'rating':
        filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'experience':
        filtered.sort((a, b) => (b.totalBookings ?? 0).compareTo(a.totalBookings ?? 0));
        break;
    }

    setState(() => _filteredAdvisors = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Advisors'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, expertise, or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFiltersAndSort();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _applyFiltersAndSort(),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Individual', 'individual'),
                const SizedBox(width: 8),
                _buildFilterChip('Agency', 'agency'),
                const SizedBox(width: 24),
                const Text('Sort by:'),
                const SizedBox(width: 8),
                _buildSortChip('Name', 'name'),
                const SizedBox(width: 8),
                _buildSortChip('Rating', 'rating'),
                const SizedBox(width: 8),
                _buildSortChip('Experience', 'experience'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Advisors List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAdvisors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No advisors found',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAdvisors,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredAdvisors.length,
                          itemBuilder: (context, index) {
                            return _buildAdvisorCard(_filteredAdvisors[index]);
                          },
                        ),
                      ),
          ),
        ],
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
        _applyFiltersAndSort();
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Color(AppConfig.primaryColor).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Color(AppConfig.primaryColor) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedSort = value);
        _applyFiltersAndSort();
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Color(AppConfig.secondaryColor).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Color(AppConfig.secondaryColor) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildAdvisorCard(UserModel advisor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(AppConfig.primaryColor),
                  child: Text(
                    advisor.fullName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
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
                        advisor.fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: advisor.role == UserRole.advisorAgency
                              ? Colors.purple.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          advisor.role == UserRole.advisorAgency ? 'Agency' : 'Individual',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: advisor.role == UserRole.advisorAgency
                                ? Colors.purple
                                : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (advisor.rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          advisor.rating!.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (advisor.expertise != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.work, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Expertise: ${advisor.expertise}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
            if (advisor.address != null || advisor.country != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${advisor.address ?? ''}${advisor.address != null && advisor.country != null ? ', ' : ''}${advisor.country ?? ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
            if (advisor.languages != null && advisor.languages!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.language, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Languages: ${advisor.languages!.join(", ")}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
            if (advisor.totalBookings != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Total Bookings: ${advisor.totalBookings}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showAdvisorDetails(advisor);
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _contactAdvisor(advisor);
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(AppConfig.primaryColor),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvisorDetails(UserModel advisor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(advisor.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', advisor.email),
              if (advisor.expertise != null)
                _buildDetailRow('Expertise', advisor.expertise!),
              if (advisor.address != null)
                _buildDetailRow('Address', advisor.address!),
              if (advisor.country != null)
                _buildDetailRow('Country', advisor.country!),
              if (advisor.totalBookings != null)
                _buildDetailRow('Total Bookings', '${advisor.totalBookings}'),
              if (advisor.rating != null)
                _buildDetailRow('Rating', '${advisor.rating!.toStringAsFixed(1)} ⭐'),
              if (advisor.languages != null && advisor.languages!.isNotEmpty)
                _buildDetailRow('Languages', advisor.languages!.join(', ')),
              if (advisor.role == UserRole.advisorAgency && advisor.businessName != null)
                _buildDetailRow('Business', advisor.businessName!),
              if (advisor.description != null)
                _buildDetailRow('Description', advisor.description!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _contactAdvisor(UserModel advisor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contacting ${advisor.fullName}...'),
        duration: const Duration(seconds: 2),
      ),
    );
    // Implement actual contact functionality here
    // Could navigate to a chat screen or open email client
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
