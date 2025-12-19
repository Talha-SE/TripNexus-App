import 'package:mongo_dart/mongo_dart.dart';

class SavedLandmarkModel {
  final ObjectId? id;
  final String userId;
  final String imagePath;
  final String analysis;
  final DateTime savedAt;

  SavedLandmarkModel({
    this.id,
    required this.userId,
    required this.imagePath,
    required this.analysis,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'imagePath': imagePath,
      'analysis': analysis,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SavedLandmarkModel.fromJson(Map<String, dynamic> json) {
    return SavedLandmarkModel(
      id: json['_id'] as ObjectId?,
      userId: json['userId'] as String,
      imagePath: json['imagePath'] as String,
      analysis: json['analysis'] as String,
      savedAt: json['savedAt'] is String
          ? DateTime.parse(json['savedAt'])
          : (json['savedAt'] as DateTime),
    );
  }
}
