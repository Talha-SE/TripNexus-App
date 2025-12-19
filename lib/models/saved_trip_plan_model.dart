import 'package:mongo_dart/mongo_dart.dart';

class SavedTripPlanModel {
  final ObjectId? id;
  final String userId;
  final String destination;
  final int duration;
  final String interests;
  final String? budget;
  final String plan;
  final DateTime savedAt;

  SavedTripPlanModel({
    this.id,
    required this.userId,
    required this.destination,
    required this.duration,
    required this.interests,
    this.budget,
    required this.plan,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'destination': destination,
      'duration': duration,
      'interests': interests,
      if (budget != null) 'budget': budget,
      'plan': plan,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SavedTripPlanModel.fromJson(Map<String, dynamic> json) {
    return SavedTripPlanModel(
      id: json['_id'] as ObjectId?,
      userId: json['userId'] as String,
      destination: json['destination'] as String,
      duration: json['duration'] as int,
      interests: json['interests'] as String,
      budget: json['budget'] as String?,
      plan: json['plan'] as String,
      savedAt: json['savedAt'] is String
          ? DateTime.parse(json['savedAt'])
          : (json['savedAt'] as DateTime),
    );
  }
}
