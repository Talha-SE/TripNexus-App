import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../config/app_config.dart';
import '../../services/mistral_service.dart';
import '../../services/mongodb_service.dart';
import '../../services/auth_service.dart';
import '../../models/saved_landmark_model.dart';
import '../../widgets/formatted_text.dart';

class LandmarkScannerScreen extends StatefulWidget {
  const LandmarkScannerScreen({Key? key}) : super(key: key);

  @override
  State<LandmarkScannerScreen> createState() => _LandmarkScannerScreenState();
}

class _LandmarkScannerScreenState extends State<LandmarkScannerScreen> {
  File? _imageFile;
  String? _analysisResult;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _analysisResult = null;
        });
        _analyzeLandmark();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _analyzeLandmark() async {
    if (_imageFile == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final mistral = MistralService.getInstance();
      final result = await mistral.analyzeLandmarkImage(base64Image);

      if (mounted) {
        if (result['success']) {
          setState(() {
            _analysisResult = result['analysis'];
            _isAnalyzing = false;
          });
        } else {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing image: $e')),
        );
      }
    }
  }

  Future<void> _saveLandmark() async {
    if (_imageFile == null || _analysisResult == null) return;

    setState(() => _isSaving = true);

    try {
      final authService = await AuthService.getInstance();
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Copy image to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final savedImagesDir = Directory('${appDir.path}/saved_landmarks');
      if (!await savedImagesDir.exists()) {
        await savedImagesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(_imageFile!.path);
      final newImagePath = '${savedImagesDir.path}/landmark_$timestamp$extension';
      await _imageFile!.copy(newImagePath);

      // Save to MongoDB
      final mongoService = await MongoDBService.getInstance();
      await mongoService.ensureConnected();
      final collection = mongoService.getSavedLandmarksCollection();

      final savedLandmark = SavedLandmarkModel(
        userId: user.id!,
        imagePath: newImagePath,
        analysis: _analysisResult!,
      );

      await collection.insertOne(savedLandmark.toJson());

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Landmark saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving landmark: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Explore Landmarks',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
          ),
          
          SingleChildScrollView(
            child: Column(
              children: [
                _buildImageSection(),
                
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isAnalyzing) _buildAnalyzingState(),
                          
                          if (_analysisResult != null) _buildResultSection(),
                          
                          if (!_isAnalyzing && _analysisResult == null) _buildActionButtons(),
                          
                          const SizedBox(height: 100), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_imageFile != null)
            Image.file(
              _imageFile!,
              fit: BoxFit.cover,
            )
          else
            Stack(
              children: [
                // Background Pattern
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/images/placeholder_pattern.png', // Fallback or assume generic
                      errorBuilder: (c, o, s) => Container(
                        color: Color(AppConfig.primaryColor).withOpacity(0.1),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(AppConfig.primaryColor).withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 50,
                          color: Color(AppConfig.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Discover the World',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(AppConfig.textPrimaryColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Point your camera at any landmark\nto learn its history',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(AppConfig.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
          // Overlay Gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start Exploring',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(AppConfig.textPrimaryColor),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                color: Color(AppConfig.primaryColor),
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: Color(AppConfig.secondaryColor),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(AppConfig.primaryColor),
                    ),
                  ),
                ),
                Icon(
                  Icons.auto_awesome,
                  size: 30,
                  color: Color(AppConfig.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing Image...',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppConfig.textPrimaryColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Identifying landmarks and history',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(AppConfig.textSecondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(AppConfig.accentColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: Color(AppConfig.accentColor),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Analysis Complete',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppConfig.textPrimaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FormattedText(
            text: _analysisResult!,
            fontSize: 15,
            textColor: Color(AppConfig.textPrimaryColor),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveLandmark,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.bookmark_border),
                label: Text(_isSaving ? 'Saving...' : 'Save Result'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: Color(AppConfig.primaryColor).withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _imageFile = null;
                    _analysisResult = null;
                  });
                },
                icon: const Icon(Icons.close),
                color: Colors.grey.shade600,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
