import 'package:mongo_dart/mongo_dart.dart';

class SavedTripPlanModel {
  final ObjectId? id;
  final String userId;
  final String destination;
  final int duration;
  final DateTime? startDate;
  final DateTime? endDate;
  final String interests;
  final String? budget;
  final String? budgetAmount;
  final String? budgetCurrency;
  final String plan;
  final DateTime savedAt;

  SavedTripPlanModel({
    this.id,
    required this.userId,
    required this.destination,
    required this.duration,
    this.startDate,
    this.endDate,
    required this.interests,
    this.budget,
    this.budgetAmount,
    this.budgetCurrency,
    required this.plan,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'destination': destination,
      'duration': duration,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'interests': interests,
      if (budget != null) 'budget': budget,
      if (budgetAmount != null) 'budgetAmount': budgetAmount,
      if (budgetCurrency != null) 'budgetCurrency': budgetCurrency,
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
      startDate: json['startDate'] == null ? null : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate'] as String),
      interests: json['interests'] as String,
      budget: json['budget'] as String?,
      budgetAmount: json['budgetAmount']?.toString(),
      budgetCurrency: json['budgetCurrency']?.toString(),
      plan: json['plan'] as String,
      savedAt: json['savedAt'] is String
          ? DateTime.parse(json['savedAt'])
          : (json['savedAt'] as DateTime),
    );
  }

  String? get displayBudget {
    final amount = budgetAmount?.trim();
    final currency = budgetCurrency?.trim();

    if (amount != null && amount.isNotEmpty && currency != null && currency.isNotEmpty) {
      return '$currency $amount';
    }

    return budget;
  }
}
