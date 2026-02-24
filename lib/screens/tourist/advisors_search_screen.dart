import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/mongodb_service.dart';

class AdvisorsSearchScreen extends StatefulWidget {
  const AdvisorsSearchScreen({super.key});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Find Advisors',
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
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Header Space & Search
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search advisors, expertise...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search_rounded, color: Color(AppConfig.primaryColor)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _applyFiltersAndSort();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onChanged: (_) => _applyFiltersAndSort(),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Individual', 'individual'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Agency', 'agency'),
                        Container(
                          height: 24,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: isDark ? Colors.white10 : Colors.grey[300],
                        ),
                        Text(
                          'Sort:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildSortChip('Name', 'name'),
                        const SizedBox(width: 8),
                        _buildSortChip('Rating', 'rating'),
                        const SizedBox(width: 8),
                        _buildSortChip('Exp.', 'experience'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Advisors List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(AppConfig.primaryColor)),
                      ),
                    )
                  : _filteredAdvisors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No advisors found',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
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
                          color: Color(AppConfig.primaryColor),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredAdvisors.length,
                            itemBuilder: (context, index) {
                              return _buildAdvisorCard(_filteredAdvisors[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = value);
        _applyFiltersAndSort();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(AppConfig.primaryColor) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(AppConfig.primaryColor) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _selectedSort == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedSort = value);
        _applyFiltersAndSort();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(AppConfig.secondaryColor).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(AppConfig.secondaryColor) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isSelected ? Color(AppConfig.secondaryColor) : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisorCard(UserModel advisor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showAdvisorDetails(advisor),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(AppConfig.primaryColor).withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.grey[100],
                            child: Text(
                              advisor.fullName.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(AppConfig.primaryColor),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  advisor.fullName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(AppConfig.textPrimaryColor),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (advisor.rating != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        advisor.rating!.toStringAsFixed(1),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: advisor.role == UserRole.advisorAgency
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              advisor.role == UserRole.advisorAgency ? 'Agency' : 'Individual',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: advisor.role == UserRole.advisorAgency
                                    ? Colors.purple
                                    : Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (advisor.expertise != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              advisor.expertise!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Info Grid
                Row(
                  children: [
                    if (advisor.country != null)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                advisor.country!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (advisor.totalBookings != null)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_outline, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${advisor.totalBookings} Bookings',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showAdvisorDetails(advisor),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Profile',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _contactAdvisor(advisor),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(AppConfig.primaryColor),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          'Contact',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
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
