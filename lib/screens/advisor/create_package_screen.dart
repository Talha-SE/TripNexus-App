import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../models/package_model.dart';
import '../../services/package_service.dart';
import '../../services/auth_service.dart';

class CreatePackageScreen extends StatefulWidget {
  final PackageModel? package; // For editing existing package

  const CreatePackageScreen({super.key, this.package});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _maxTravelersController = TextEditingController();
  
  final List<TextEditingController> _includesControllers = [];
  final List<TextEditingController> _excludesControllers = [];
  final List<TextEditingController> _itineraryControllers = [];
  
  String _selectedCategory = 'Adventure';
  PackageStatus _status = PackageStatus.draft;
  bool _isLoading = false;

  final List<String> _categories = [
    'Adventure',
    'Cultural',
    'Relaxation',
    'Wildlife',
    'Beach',
    'Mountain',
    'City Tours',
    'Honeymoon',
    'Family',
    'Solo Travel',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.package != null) {
      _loadPackageData();
    } else {
      _addIncludesField();
      _addExcludesField();
      _addItineraryField();
    }
  }

  void _loadPackageData() {
    final pkg = widget.package!;
    _titleController.text = pkg.title;
    _descriptionController.text = pkg.description;
    _priceController.text = pkg.price.toString();
    _durationController.text = pkg.duration.toString();
    _destinationController.text = pkg.destination;
    _maxTravelersController.text = pkg.maxTravelers.toString();
    _selectedCategory = pkg.category;
    _status = pkg.status;

    for (var item in pkg.includes) {
      final controller = TextEditingController(text: item);
      _includesControllers.add(controller);
    }
    if (_includesControllers.isEmpty) _addIncludesField();

    for (var item in pkg.excludes) {
      final controller = TextEditingController(text: item);
      _excludesControllers.add(controller);
    }
    if (_excludesControllers.isEmpty) _addExcludesField();

    for (var item in pkg.itinerary) {
      final controller = TextEditingController(text: item);
      _itineraryControllers.add(controller);
    }
    if (_itineraryControllers.isEmpty) _addItineraryField();
  }

  void _addIncludesField() {
    setState(() {
      _includesControllers.add(TextEditingController());
    });
  }

  void _addExcludesField() {
    setState(() {
      _excludesControllers.add(TextEditingController());
    });
  }

  void _addItineraryField() {
    setState(() {
      _itineraryControllers.add(TextEditingController());
    });
  }

  void _removeIncludesField(int index) {
    if (_includesControllers.length > 1) {
      setState(() {
        _includesControllers[index].dispose();
        _includesControllers.removeAt(index);
      });
    }
  }

  void _removeExcludesField(int index) {
    if (_excludesControllers.length > 1) {
      setState(() {
        _excludesControllers[index].dispose();
        _excludesControllers.removeAt(index);
      });
    }
  }

  void _removeItineraryField(int index) {
    if (_itineraryControllers.length > 1) {
      setState(() {
        _itineraryControllers[index].dispose();
        _itineraryControllers.removeAt(index);
      });
    }
  }

  Future<void> _savePackage({bool makeLive = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = await AuthService.getInstance();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final includes = _includesControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      final excludes = _excludesControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      final itinerary = _itineraryControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final package = PackageModel(
        id: widget.package?.id,
        advisorId: currentUser.id!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        duration: int.parse(_durationController.text.trim()),
        destination: _destinationController.text.trim(),
        includes: includes,
        excludes: excludes,
        itinerary: itinerary,
        maxTravelers: int.parse(_maxTravelersController.text.trim()),
        category: _selectedCategory,
        status: makeLive ? PackageStatus.live : _status,
        createdAt: widget.package?.createdAt,
      );

      final packageService = await PackageService.getInstance();

      if (widget.package == null) {
        // Create new package
        final packageId = await packageService.createPackage(package);
        if (packageId != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(makeLive ? 'Package created and made live!' : 'Package saved as draft!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Update existing package
        final success = await packageService.updatePackage(widget.package!.id!, package);
        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(makeLive ? 'Package updated and made live!' : 'Package updated!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving package: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.package == null ? 'Create Package' : 'Edit Package',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _titleController,
              label: 'Package Title',
              hint: 'e.g., 5-Day Himalayan Adventure',
              validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your package...',
              maxLines: 4,
              validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildResponsivePair(
              left: _buildTextField(
                controller: _priceController,
                label: 'Price',
                hint: 'USD 1000',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(val!) == null) return 'Invalid';
                  return null;
                },
              ),
              right: _buildTextField(
                controller: _durationController,
                label: 'Duration',
                hint: '5 days',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(val!) == null) return 'Invalid';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _destinationController,
              label: 'Destination',
              hint: 'e.g., Kathmandu, Nepal',
              validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildResponsivePair(
              left: _buildTextField(
                controller: _maxTravelersController,
                label: 'Travelers',
                hint: 'Max 10',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(val!) == null) return 'Invalid';
                  return null;
                },
              ),
              right: _buildCategoryDropdown(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('What\'s Included'),
            const SizedBox(height: 12),
            ..._buildDynamicFields(
              _includesControllers,
              'e.g., Accommodation, Meals',
              _addIncludesField,
              _removeIncludesField,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('What\'s Excluded'),
            const SizedBox(height: 12),
            ..._buildDynamicFields(
              _excludesControllers,
              'e.g., Flight tickets, Personal expenses',
              _addExcludesField,
              _removeExcludesField,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Itinerary'),
            const SizedBox(height: 12),
            ..._buildDynamicFields(
              _itineraryControllers,
              'Day 1: Arrival and city tour',
              _addItineraryField,
              _removeItineraryField,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _savePackage(makeLive: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Color(AppConfig.primaryColor)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save as Draft',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _savePackage(makeLive: true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Color(AppConfig.primaryColor),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Make Live',
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsivePair({
    required Widget left,
    required Widget right,
    double spacing = 12,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: left),
            SizedBox(width: spacing),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(AppConfig.textPrimaryColor),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        alignLabelWithHint: maxLines > 1,
        labelStyle: GoogleFonts.poppins(fontSize: 14),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Color(AppConfig.textSecondaryColor),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(AppConfig.primaryColor), width: 1.4),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
      ),
      style: GoogleFonts.poppins(fontSize: 15),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded),
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(AppConfig.textPrimaryColor),
      ),
      decoration: InputDecoration(
        labelText: 'Category',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.poppins(fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(AppConfig.primaryColor), width: 1.4),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
      ),
      selectedItemBuilder: (context) {
        return _categories
            .map(
              (category) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            )
            .toList();
      },
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
    );
  }

  List<Widget> _buildDynamicFields(
    List<TextEditingController> controllers,
    String hint,
    VoidCallback onAdd,
    void Function(int) onRemove,
  ) {
    return [
      ...List.generate(controllers.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers[index],
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (controllers.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => onRemove(index),
                ),
            ],
          ),
        );
      }),
      TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add More'),
      ),
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _destinationController.dispose();
    _maxTravelersController.dispose();
    for (var controller in _includesControllers) {
      controller.dispose();
    }
    for (var controller in _excludesControllers) {
      controller.dispose();
    }
    for (var controller in _itineraryControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
