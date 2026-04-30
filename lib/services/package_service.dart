import 'package:mongo_dart/mongo_dart.dart';
import '../models/package_model.dart';
import '../models/user_model.dart';
import 'mongodb_service.dart';

class PackageService {
  static PackageService? _instance;
  late MongoDBService _mongoService;

  PackageService._();

  static Future<PackageService> getInstance() async {
    if (_instance == null) {
      final service = PackageService._();
      try {
        service._mongoService = await MongoDBService.getInstance();
        await service._mongoService.ensureConnected();
        _instance = service;
      } catch (e) {
        print('Error initializing PackageService: $e');
        _instance = null;
        rethrow;
      }
    }
    return _instance!;
  }

  // Helper to safely convert string or ObjectId to ObjectId
  ObjectId _toObjectId(dynamic id) {
    if (id is ObjectId) {
      return id;
    } else if (id is String) {
      // Handle strings like ObjectId("...") or raw hex
      final objIdMatch = RegExp(r'ObjectId\("([0-9a-fA-F]{24})"\)').firstMatch(id);
      if (objIdMatch != null) {
        return ObjectId.fromHexString(objIdMatch.group(1)!);
      } else if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id)) {
        return ObjectId.fromHexString(id);
      }
    }
    throw ArgumentError('Invalid ObjectId: $id');
  }

  // Get packages collection
  DbCollection _getPackagesCollection() {
    return _mongoService.getPackagesCollection();
  }

  // Get bookings collection
  DbCollection _getBookingsCollection() {
    return _mongoService.getPackageBookingsCollection();
  }

  // Public access for dashboard updates
  DbCollection getBookingsCollectionPublic() {
    return _getBookingsCollection();
  }

  // Get messages collection
  DbCollection _getMessagesCollection() {
    return _mongoService.getPackageMessagesCollection();
  }

  // Create a new package
  Future<String?> createPackage(PackageModel package) async {
    try {
      final collection = _getPackagesCollection();
      final packageData = package.toJson();
      packageData.remove('_id'); // Remove id for new creation
      
      final result = await collection.insertOne(packageData);
      return result.id?.toHexString();
    } catch (e) {
      print('Error creating package: $e');
      rethrow;
    }
  }

  // Update package
  Future<bool> updatePackage(String packageId, PackageModel package) async {
    try {
      final collection = _getPackagesCollection();
      final packageData = package.toJson();
      packageData['updatedAt'] = DateTime.now().toIso8601String();
      
      final result = await collection.updateOne(
        where.id(_toObjectId(packageId)),
        modify.set('title', packageData['title'])
            .set('description', packageData['description'])
            .set('price', packageData['price'])
            .set('duration', packageData['duration'])
            .set('destination', packageData['destination'])
            .set('includes', packageData['includes'])
            .set('excludes', packageData['excludes'])
            .set('itinerary', packageData['itinerary'])
            .set('images', packageData['images'])
            .set('status', packageData['status'])
            .set('maxTravelers', packageData['maxTravelers'])
            .set('category', packageData['category'])
            .set('updatedAt', packageData['updatedAt']),
      );
      
      return result.isSuccess;
    } catch (e) {
      print('Error updating package: $e');
      rethrow;
    }
  }

  // Delete package
  Future<bool> deletePackage(String packageId) async {
    try {
      final collection = _getPackagesCollection();
      final result = await collection.deleteOne(
        where.id(_toObjectId(packageId)),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error deleting package: $e');
      rethrow;
    }
  }

  // Get packages by advisor
  Future<List<PackageModel>> getAdvisorPackages(String advisorId, {PackageStatus? status}) async {
    try {
      final collection = _getPackagesCollection();
      
      final query = <String, dynamic>{'advisorId': advisorId};
      if (status != null) {
        query['status'] = status.value;
      }
      
      final packages = await collection.find(query).toList();
      return packages.map((doc) => PackageModel.fromJson(doc)).toList();
    } catch (e) {
      print('Error getting advisor packages: $e');
      rethrow;
    }
  }

  // Get all live packages with filters
  Future<List<PackageModel>> getLivePackages({
    String? advisorType, // 'advisor_individual' or 'advisor_agency'
    double? minPrice,
    double? maxPrice,
    String? category,
    String? sortBy, // 'latest', 'price_low', 'price_high', 'rating'
  }) async {
    try {
      final packagesCollection = _getPackagesCollection();
      final usersCollection = _mongoService.getUsersCollection();
      
      // Build query
      final query = <String, dynamic>{'status': 'live'};
      
      if (minPrice != null || maxPrice != null) {
        query['price'] = <String, dynamic>{};
        if (minPrice != null) query['price']['\$gte'] = minPrice;
        if (maxPrice != null) query['price']['\$lte'] = maxPrice;
      }
      
      if (category != null && category.isNotEmpty) {
        query['category'] = category;
      }
      
      
      // Get packages first
      var packages = await packagesCollection.find(query).toList();
      
      // Apply sorting in memory
      if (sortBy != null) {
        switch (sortBy) {
          case 'latest':
            packages.sort((a, b) {
              final aDate = a['createdAt'] as String? ?? '';
              final bDate = b['createdAt'] as String? ?? '';
              return bDate.compareTo(aDate);
            });
            break;
          case 'price_low':
            packages.sort((a, b) => ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0));
            break;
          case 'price_high':
            packages.sort((a, b) => ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0));
            break;
          case 'rating':
            packages.sort((a, b) => ((b['rating'] as num?) ?? 0).compareTo((a['rating'] as num?) ?? 0));
            break;
        }
      }
      
      final packageModels = packages.map((doc) => PackageModel.fromJson(doc)).toList();
      
      // Filter by advisor type if specified
      if (advisorType != null) {
        final advisorIds = packageModels.map((p) => p.advisorId).toSet().toList();
        final advisors = await usersCollection.find(
          where.oneFrom('_id', advisorIds.map((id) => _toObjectId(id)).toList())
              .and(where.eq('role', advisorType))
        ).toList();
        
        final filteredAdvisorIds = advisors.map((a) => a['_id'].toHexString()).toSet();
        return packageModels.where((p) => filteredAdvisorIds.contains(p.advisorId)).toList();
      }
      
      return packageModels;
    } catch (e) {
      print('Error getting live packages: $e');
      rethrow;
    }
  }

  // Get package by ID
  Future<PackageModel?> getPackageById(String packageId) async {
    try {
      final collection = _getPackagesCollection();
      final package = await collection.findOne(
        where.id(_toObjectId(packageId)),
      );
      
      if (package != null) {
        return PackageModel.fromJson(package);
      }
      return null;
    } catch (e) {
      print('Error getting package by ID: $e');
      rethrow;
    }
  }

  // Get package with advisor info
  Future<Map<String, dynamic>?> getPackageWithAdvisorInfo(String packageId) async {
    try {
      final package = await getPackageById(packageId);
      if (package == null) return null;
      
      final usersCollection = _mongoService.getUsersCollection();
      final advisor = await usersCollection.findOne(
        where.id(_toObjectId(package.advisorId)),
      );
      
      if (advisor != null) {
        final advisorModel = UserModel.fromJson(advisor);
        return {
          'package': package,
          'advisor': advisorModel,
        };
      }
      
      return {'package': package};
    } catch (e) {
      print('Error getting package with advisor info: $e');
      rethrow;
    }
  }

  // Create booking
  Future<String?> createBooking(PackageBooking booking) async {
    try {
      final collection = _getBookingsCollection();
      final bookingData = booking.toJson();
      bookingData.remove('_id');
      
      final result = await collection.insertOne(bookingData);
      return result.id?.toHexString();
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  // Get bookings for traveler
  Future<List<PackageBooking>> getTravelerBookings(String travelerId) async {
    try {
      final collection = _getBookingsCollection();
      final bookings = await collection.find(
        where.eq('travelerId', travelerId),
      ).toList();
      
      return bookings.map((doc) => PackageBooking.fromJson(doc)).toList();
    } catch (e) {
      print('Error getting traveler bookings: $e');
      rethrow;
    }
  }

  // Get bookings for advisor
  Future<List<PackageBooking>> getAdvisorBookings(String advisorId) async {
    try {
      final collection = _getBookingsCollection();
      final bookings = await collection.find(
        where.eq('advisorId', advisorId),
      ).toList();
      
      return bookings.map((doc) => PackageBooking.fromJson(doc)).toList();
    } catch (e) {
      print('Error getting advisor bookings: $e');
      rethrow;
    }
  }

  // Send message
  Future<String?> sendMessage(PackageMessage message) async {
    try {
      final collection = _getMessagesCollection();
      final messageData = message.toJson();
      messageData.remove('_id');
      
      final result = await collection.insertOne(messageData);
      return result.id?.toHexString();
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a package
  Future<List<PackageMessage>> getPackageMessages(String packageId, String userId) async {
    try {
      final collection = _getMessagesCollection();
      final messages = await collection.find(
        where.eq('packageId', packageId),
      ).toList();
      
      // Filter messages for the user in memory
      final filteredMessages = messages.where((msg) {
        return msg['senderId'] == userId || msg['receiverId'] == userId;
      }).toList();
      
      // Sort by timestamp
      filteredMessages.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));
      
      return filteredMessages.map((doc) => PackageMessage.fromJson(doc)).toList();
    } catch (e) {
      print('Error getting package messages: $e');
      rethrow;
    }
  }

  // Mark message as read
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      final collection = _getMessagesCollection();
      final result = await collection.updateOne(
        where.id(_toObjectId(messageId)),
        modify.set('isRead', true),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }

  // Update package status
  Future<bool> updatePackageStatus(String packageId, PackageStatus status) async {
    try {
      final collection = _getPackagesCollection();
      final result = await collection.updateOne(
        where.id(_toObjectId(packageId)),
        modify.set('status', status.value)
            .set('updatedAt', DateTime.now().toIso8601String()),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error updating package status: $e');
      rethrow;
    }
  }

  // Get package categories
  Future<List<String>> getCategories() async {
    try {
      final collection = _getPackagesCollection();
      final results = await collection.distinct('category');
      return (results as List).map((c) => c.toString()).toList();
    } catch (e) {
      print('Error getting categories: $e');
      return ['Adventure', 'Cultural', 'Relaxation', 'Wildlife', 'Beach', 'Mountain', 'City Tours'];
    }
  }
}
