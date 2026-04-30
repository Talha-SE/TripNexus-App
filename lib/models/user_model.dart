import 'package:mongo_dart/mongo_dart.dart';

enum UserRole {
  tourist,
  advisorIndividual,
  advisorAgency,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.tourist:
        return 'tourist';
      case UserRole.advisorIndividual:
        return 'advisor_individual';
      case UserRole.advisorAgency:
        return 'advisor_agency';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'tourist':
        return UserRole.tourist;
      case 'advisor_individual':
        return UserRole.advisorIndividual;
      case 'advisor_agency':
        return UserRole.advisorAgency;
      default:
        return UserRole.tourist;
    }
  }
}

class UserModel {
  final String? id;
  final String email;
  final String? password;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;
  final bool isVerified;
  
  // For advisors
  final String? businessName;
  final String? description;
  final String? expertise;
  final List<String>? certifications;
  final double? rating;
  final int? totalBookings;
  final String? address;
  final String? country;
  final List<String>? languages;
  final String? bio;
  
  UserModel({
    this.id,
    required this.email,
    this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.profileImage,
    DateTime? createdAt,
    this.isVerified = false,
    this.businessName,
    this.description,
    this.expertise,
    this.certifications,
    this.rating,
    this.totalBookings,
    this.address,
    this.country,
    this.languages,
    this.bio,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Normalize _id to a 24-char hex string (avoid ObjectId.toString() which gives "ObjectId(\"...\")")
    String? normalizedId;
    final rawId = json['_id'];
    if (rawId != null) {
      if (rawId is ObjectId) {
        normalizedId = rawId.toHexString();
      } else if (rawId is String) {
        final objIdMatch = RegExp(r'ObjectId\("([0-9a-fA-F]{24})"\)').firstMatch(rawId);
        if (objIdMatch != null) {
          normalizedId = objIdMatch.group(1);
        } else {
          normalizedId = rawId;
        }
      }
    }
    return UserModel(
      id: normalizedId,
      email: json['email'] as String,
      password: json['password'] as String?,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: UserRoleExtension.fromString(json['role'] as String),
      profileImage: json['profileImage'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isVerified: json['isVerified'] as bool? ?? false,
      businessName: json['businessName'] as String?,
      description: json['description'] as String?,
      expertise: json['expertise'] as String?,
      certifications: (json['certifications'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      rating: (json['rating'] as num?)?.toDouble(),
      totalBookings: json['totalBookings'] as int?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'email': email,
      if (password != null) 'password': password,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role.value,
      if (profileImage != null) 'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      if (businessName != null) 'businessName': businessName,
      if (description != null) 'description': description,
      if (expertise != null) 'expertise': expertise,
      if (certifications != null) 'certifications': certifications,
      if (rating != null) 'rating': rating,
      if (totalBookings != null) 'totalBookings': totalBookings,
      if (address != null) 'address': address,
      if (country != null) 'country': country,
      if (languages != null) 'languages': languages,
      if (bio != null) 'bio': bio,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? password,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    String? profileImage,
    DateTime? createdAt,
    bool? isVerified,
    String? businessName,
    String? description,
    String? expertise,
    List<String>? certifications,
    double? rating,
    int? totalBookings,
    String? address,
    String? country,
    List<String>? languages,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      expertise: expertise ?? this.expertise,
      certifications: certifications ?? this.certifications,
      rating: rating ?? this.rating,
      totalBookings: totalBookings ?? this.totalBookings,
      address: address ?? this.address,
      country: country ?? this.country,
      languages: languages ?? this.languages,
    );
  }

  bool get isAdvisor => role == UserRole.advisorIndividual || role == UserRole.advisorAgency;
  bool get isTourist => role == UserRole.tourist;
}
