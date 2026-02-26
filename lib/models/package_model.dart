import 'package:mongo_dart/mongo_dart.dart';

enum PackageStatus {
  draft,
  live,
  archived,
}

extension PackageStatusExtension on PackageStatus {
  String get value {
    switch (this) {
      case PackageStatus.draft:
        return 'draft';
      case PackageStatus.live:
        return 'live';
      case PackageStatus.archived:
        return 'archived';
    }
  }

  static PackageStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return PackageStatus.draft;
      case 'live':
        return PackageStatus.live;
      case 'archived':
        return PackageStatus.archived;
      default:
        return PackageStatus.draft;
    }
  }
}

class PackageModel {
  final String? id;
  final String advisorId;
  final String title;
  final String description;
  final double price;
  final int duration; // in days
  final String destination;
  final List<String> includes;
  final List<String> excludes;
  final List<String> itinerary;
  final List<String> images;
  final PackageStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int maxTravelers;
  final String category; // e.g., "Adventure", "Cultural", "Relaxation", etc.
  final Map<String, dynamic>? advisorInfo; // Cached advisor info for quick display
  final int totalBookings;
  final double? rating;

  PackageModel({
    this.id,
    required this.advisorId,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.destination,
    this.includes = const [],
    this.excludes = const [],
    this.itinerary = const [],
    this.images = const [],
    this.status = PackageStatus.draft,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.maxTravelers = 10,
    this.category = 'General',
    this.advisorInfo,
    this.totalBookings = 0,
    this.rating,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    // Normalize _id to a 24-char hex string when possible
    String? normalizedId;
    final rawId = json['_id'];
    if (rawId != null) {
      if (rawId is ObjectId) {
        normalizedId = rawId.toHexString();
      } else if (rawId is String) {
        // Handle strings like ObjectId("...") or raw hex
        final objIdMatch = RegExp(r'ObjectId\("([0-9a-fA-F]{24})"\)').firstMatch(rawId);
        if (objIdMatch != null) {
          normalizedId = objIdMatch.group(1);
        } else if (RegExp(r'^[0-9a-fA-F]{24}\$').hasMatch(rawId)) {
          normalizedId = rawId;
        } else {
          normalizedId = rawId;
        }
      }
    }

    return PackageModel(
      id: normalizedId,
      advisorId: json['advisorId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      duration: json['duration'] as int,
      destination: json['destination'] as String,
      includes: (json['includes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      excludes: (json['excludes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      itinerary: (json['itinerary'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: PackageStatusExtension.fromString(json['status'] as String? ?? 'draft'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      maxTravelers: json['maxTravelers'] as int? ?? 10,
      category: json['category'] as String? ?? 'General',
      advisorInfo: json['advisorInfo'] as Map<String, dynamic>?,
      totalBookings: json['totalBookings'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'advisorId': advisorId,
      'title': title,
      'description': description,
      'price': price,
      'duration': duration,
      'destination': destination,
      'includes': includes,
      'excludes': excludes,
      'itinerary': itinerary,
      'images': images,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'maxTravelers': maxTravelers,
      'category': category,
      if (advisorInfo != null) 'advisorInfo': advisorInfo,
      'totalBookings': totalBookings,
      if (rating != null) 'rating': rating,
    };
  }

  PackageModel copyWith({
    String? id,
    String? advisorId,
    String? title,
    String? description,
    double? price,
    int? duration,
    String? destination,
    List<String>? includes,
    List<String>? excludes,
    List<String>? itinerary,
    List<String>? images,
    PackageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? maxTravelers,
    String? category,
    Map<String, dynamic>? advisorInfo,
    int? totalBookings,
    double? rating,
  }) {
    return PackageModel(
      id: id ?? this.id,
      advisorId: advisorId ?? this.advisorId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      destination: destination ?? this.destination,
      includes: includes ?? this.includes,
      excludes: excludes ?? this.excludes,
      itinerary: itinerary ?? this.itinerary,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      maxTravelers: maxTravelers ?? this.maxTravelers,
      category: category ?? this.category,
      advisorInfo: advisorInfo ?? this.advisorInfo,
      totalBookings: totalBookings ?? this.totalBookings,
      rating: rating ?? this.rating,
    );
  }
}

// Booking model for package acceptance
class PackageBooking {
  final String? id;
  final String packageId;
  final String travelerId;
  final String advisorId;
  final DateTime bookingDate;
  final String status; // pending, accepted, rejected, completed
  final String paymentMethod; // cash, online
  final double amount;
  final String? notes;
  final DateTime createdAt;

  PackageBooking({
    this.id,
    required this.packageId,
    required this.travelerId,
    required this.advisorId,
    required this.bookingDate,
    this.status = 'pending',
    this.paymentMethod = 'cash',
    required this.amount,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PackageBooking.fromJson(Map<String, dynamic> json) {
    return PackageBooking(
      id: json['_id']?.toString(),
      packageId: json['packageId'] as String,
      travelerId: json['travelerId'] as String,
      advisorId: json['advisorId'] as String,
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'packageId': packageId,
      'travelerId': travelerId,
      'advisorId': advisorId,
      'bookingDate': bookingDate.toIso8601String(),
      'status': status,
      'paymentMethod': paymentMethod,
      'amount': amount,
      if (notes != null) 'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Message model for package-specific messaging
class PackageMessage {
  final String? id;
  final String packageId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  PackageMessage({
    this.id,
    required this.packageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PackageMessage.fromJson(Map<String, dynamic> json) {
    return PackageMessage(
      id: json['_id']?.toString(),
      packageId: json['packageId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      message: json['message'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'packageId': packageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
