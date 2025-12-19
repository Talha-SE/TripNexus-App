import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';
import '../../services/mongodb_service.dart';
import '../../models/saved_landmark_model.dart';
import '../../widgets/formatted_text.dart';

class SavedLandmarksScreen extends StatefulWidget {
  const SavedLandmarksScreen({Key? key}) : super(key: key);

  @override
  State<SavedLandmarksScreen> createState() => _SavedLandmarksScreenState();
}

class _SavedLandmarksScreenState extends State<SavedLandmarksScreen> {
  List<SavedLandmarkModel> _savedLandmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLandmarks();
  }

  Future<void> _loadSavedLandmarks() async {
    setState(() => _isLoading = true);

    try {
      final authService = await AuthService.getInstance();
      final user = authService.currentUser;

      if (user == null) return;

      final mongoService = await MongoDBService.getInstance();
      await mongoService.ensureConnected();
      final collection = mongoService.getSavedLandmarksCollection();
      
      final landmarks = await collection
          .find({'userId': user.id})
          .toList();
      
      setState(() {
        _savedLandmarks = landmarks
            .map((l) => SavedLandmarkModel.fromJson(l))
            .toList()
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading landmarks: $e')),
        );
      }
    }
  }

  Future<void> _deleteLandmark(SavedLandmarkModel landmark) async {
    try {
      final mongoService = await MongoDBService.getInstance();
      await mongoService.ensureConnected();
      final collection = mongoService.getSavedLandmarksCollection();
      
      await collection.deleteOne({'_id': landmark.id});

      // Delete image file
      try {
        final file = File(landmark.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting image file: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Landmark deleted')),
        );
        _loadSavedLandmarks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  void _showLandmarkDetails(SavedLandmarkModel landmark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(landmark.imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 64),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.location_city,
                          color: Color(AppConfig.primaryColor),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Landmark Information',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(AppConfig.textPrimaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saved ${DateFormat('MMM dd, yyyy • hh:mm a').format(landmark.savedAt)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Color(AppConfig.textSecondaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormattedText(
                      text: landmark.analysis,
                      fontSize: 14,
                      textColor: Color(AppConfig.textPrimaryColor),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: this.context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Landmark'),
                            content: const Text('Are you sure you want to delete this saved landmark?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteLandmark(landmark);
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
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppConfig.errorColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Landmarks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedLandmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No saved landmarks',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan landmarks and save them here',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSavedLandmarks,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _savedLandmarks.length,
                    itemBuilder: (context, index) {
                      final landmark = _savedLandmarks[index];
                      return GestureDetector(
                        onTap: () => _showLandmarkDetails(landmark),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Image.file(
                                  File(landmark.imagePath),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(landmark.savedAt),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(AppConfig.textPrimaryColor),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      landmark.analysis.split('\n').first,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Color(AppConfig.textSecondaryColor),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
