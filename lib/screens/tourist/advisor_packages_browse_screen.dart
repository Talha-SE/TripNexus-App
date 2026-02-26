import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../models/package_model.dart';
import '../../services/package_service.dart';
import 'package_details_screen.dart';

class AdvisorPackagesBrowseScreen extends StatefulWidget {
  const AdvisorPackagesBrowseScreen({super.key});

  @override
  State<AdvisorPackagesBrowseScreen> createState() => _AdvisorPackagesBrowseScreenState();
}

class _AdvisorPackagesBrowseScreenState extends State<AdvisorPackagesBrowseScreen> {
  final _searchController = TextEditingController();
  List<PackageModel> _allPackages = [];
  List<PackageModel> _packages = [];
  bool _isLoading = true;
  
  String? _selectedAdvisorType; // 'advisor_individual' or 'advisor_agency'
  double _minPrice = 0;
  double _maxPrice = 10000;
  String? _selectedCategory;
  String _sortBy = 'latest'; // 'latest', 'price_low', 'price_high', 'rating'

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);

    try {
      final packageService = await PackageService.getInstance();
      final packages = await packageService.getLivePackages(
        advisorType: _selectedAdvisorType,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 10000 ? _maxPrice : null,
        category: _selectedCategory,
        sortBy: _sortBy,
      );

      if (mounted) {
        setState(() {
          _allPackages = packages;
          _packages = packages;
          _isLoading = false;
        });
        _applySearch();
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

  void _applySearch() {
    if (_searchController.text.isEmpty) {
      setState(() => _packages = _allPackages);
      return;
    }

    final query = _searchController.text.toLowerCase();
    setState(() {
      _packages = _allPackages.where((package) {
        return package.title.toLowerCase().contains(query) ||
            package.description.toLowerCase().contains(query) ||
            package.destination.toLowerCase().contains(query) ||
            package.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFiltersSheet(),
    );
  }

  Widget _buildFiltersSheet() {
    String? tempAdvisorType = _selectedAdvisorType;
    double tempMinPrice = _minPrice;
    double tempMaxPrice = _maxPrice;
    String? tempCategory = _selectedCategory;
    String tempSortBy = _sortBy;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempAdvisorType = null;
                            tempMinPrice = 0;
                            tempMaxPrice = 10000;
                            tempCategory = null;
                            tempSortBy = 'latest';
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Text(
                          'Advisor Type',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: tempAdvisorType == null,
                              onSelected: (selected) {
                                setModalState(() => tempAdvisorType = null);
                              },
                            ),
                            FilterChip(
                              label: const Text('Individual'),
                              selected: tempAdvisorType == 'advisor_individual',
                              onSelected: (selected) {
                                setModalState(() => tempAdvisorType = 'advisor_individual');
                              },
                            ),
                            FilterChip(
                              label: const Text('Agency'),
                              selected: tempAdvisorType == 'advisor_agency',
                              onSelected: (selected) {
                                setModalState(() => tempAdvisorType = 'advisor_agency');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Price Range: \$${tempMinPrice.toInt()} - \$${tempMaxPrice.toInt()}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        RangeSlider(
                          values: RangeValues(tempMinPrice, tempMaxPrice),
                          min: 0,
                          max: 10000,
                          divisions: 100,
                          labels: RangeLabels(
                            '\$${tempMinPrice.toInt()}',
                            '\$${tempMaxPrice.toInt()}',
                          ),
                          onChanged: (values) {
                            setModalState(() {
                              tempMinPrice = values.start;
                              tempMaxPrice = values.end;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Sort By',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Latest'),
                              selected: tempSortBy == 'latest',
                              onSelected: (selected) {
                                setModalState(() => tempSortBy = 'latest');
                              },
                            ),
                            FilterChip(
                              label: const Text('Price: Low to High'),
                              selected: tempSortBy == 'price_low',
                              onSelected: (selected) {
                                setModalState(() => tempSortBy = 'price_low');
                              },
                            ),
                            FilterChip(
                              label: const Text('Price: High to Low'),
                              selected: tempSortBy == 'price_high',
                              onSelected: (selected) {
                                setModalState(() => tempSortBy = 'price_high');
                              },
                            ),
                            FilterChip(
                              label: const Text('Top Rated'),
                              selected: tempSortBy == 'rating',
                              onSelected: (selected) {
                                setModalState(() => tempSortBy = 'rating');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedAdvisorType = tempAdvisorType;
                          _minPrice = tempMinPrice;
                          _maxPrice = tempMaxPrice;
                          _selectedCategory = tempCategory;
                          _sortBy = tempSortBy;
                        });
                        Navigator.pop(context);
                        _loadPackages();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Color(AppConfig.primaryColor),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Advisor Packages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 56),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search packages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) => _applySearch(),
            ),
          ),
          if (_selectedAdvisorType != null || _minPrice > 0 || _maxPrice < 10000)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Active filters',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(AppConfig.textSecondaryColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedAdvisorType = null;
                        _minPrice = 0;
                        _maxPrice = 10000;
                        _selectedCategory = null;
                      });
                      _loadPackages();
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _packages.isEmpty
                    ? _buildEmptyState()
                    : _buildPackagesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
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
            'Try adjusting your filters',
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
      padding: const EdgeInsets.all(16),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PackageDetailsScreen(packageId: package.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package Image Placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    Color(AppConfig.primaryColor).withOpacity(0.7),
                    Color(AppConfig.primaryColor),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.landscape,
                      size: 64,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        package.category,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(AppConfig.primaryColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(AppConfig.textSecondaryColor),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        package.destination,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(AppConfig.textSecondaryColor),
                        ),
                      ),
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
                      _buildInfoChip(Icons.access_time, '${package.duration} days'),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.people, '${package.maxTravelers} max'),
                      const Spacer(),
                      Text(
                        '\$${package.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(AppConfig.primaryColor),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
