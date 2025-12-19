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
      appBar: AppBar(
        title: Text(
          'Landmark Scanner',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_imageFile != null)
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    _imageFile!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.all(16),
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(AppConfig.primaryColor).withValues(alpha: 0.1),
                      Color(AppConfig.accentColor).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(AppConfig.primaryColor).withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(AppConfig.primaryColor).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 60,
                        color: Color(AppConfig.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Discover Landmarks',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(AppConfig.textPrimaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Take or upload a photo to identify landmarks with AI',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(AppConfig.textSecondaryColor),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded, size: 22),
                          label: Text(
                            'Take Photo',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(AppConfig.primaryColor),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded, size: 22),
                          label: Text(
                            'Gallery',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Color(AppConfig.primaryColor),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isAnalyzing) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Color(AppConfig.primaryColor).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(AppConfig.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Analyzing landmark...',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(AppConfig.textPrimaryColor),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Our AI is identifying the landmark',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Color(AppConfig.textSecondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_analysisResult != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_city,
                                color: Color(AppConfig.primaryColor),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Landmark Information',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(AppConfig.primaryColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FormattedText(
                            text: _analysisResult!,
                            fontSize: 14,
                            textColor: Color(AppConfig.textPrimaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isAnalyzing || _isSaving ? null : _analyzeLandmark,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : _saveLandmark,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.bookmark),
                            label: Text(_isSaving ? 'Saving...' : 'Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(AppConfig.accentColor),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isAnalyzing || _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _imageFile = null;
                                      _analysisResult = null;
                                    });
                                  },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('New Scan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(AppConfig.secondaryColor),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
