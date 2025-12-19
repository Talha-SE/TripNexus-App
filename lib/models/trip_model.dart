class TripModel {
  final String? id;
  final String userId;
  final String title;
  final String destination;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final double? budget;
  final List<String>? activities;
  final String? weatherInfo;
  final List<String>? landmarks;
  final String? aiRecommendations;
  final bool isEcoFriendly;
  final DateTime createdAt;
  final String? advisorId;
  final String status; // planned, ongoing, completed, cancelled

  TripModel({
    this.id,
    required this.userId,
    required this.title,
    required this.destination,
    this.description,
    required this.startDate,
    required this.endDate,
    this.budget,
    this.activities,
    this.weatherInfo,
    this.landmarks,
    this.aiRecommendations,
    this.isEcoFriendly = false,
    DateTime? createdAt,
    this.advisorId,
    this.status = 'planned',
  }) : createdAt = createdAt ?? DateTime.now();

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['_id']?.toString(),
      userId: json['userId'] as String,
      title: json['title'] as String,
      destination: json['destination'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      budget: (json['budget'] as num?)?.toDouble(),
      activities: (json['activities'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      weatherInfo: json['weatherInfo'] as String?,
      landmarks: (json['landmarks'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      aiRecommendations: json['aiRecommendations'] as String?,
      isEcoFriendly: json['isEcoFriendly'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      advisorId: json['advisorId'] as String?,
      status: json['status'] as String? ?? 'planned',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'title': title,
      'destination': destination,
      if (description != null) 'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (budget != null) 'budget': budget,
      if (activities != null) 'activities': activities,
      if (weatherInfo != null) 'weatherInfo': weatherInfo,
      if (landmarks != null) 'landmarks': landmarks,
      if (aiRecommendations != null) 'aiRecommendations': aiRecommendations,
      'isEcoFriendly': isEcoFriendly,
      'createdAt': createdAt.toIso8601String(),
      if (advisorId != null) 'advisorId': advisorId,
      'status': status,
    };
  }
}
