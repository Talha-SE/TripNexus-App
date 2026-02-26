import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/package_service.dart';
import '../../services/mongodb_service.dart';
import '../tourist/package_chat_screen.dart';

class AdvisorMessagesScreen extends StatefulWidget {
  const AdvisorMessagesScreen({super.key});

  @override
  State<AdvisorMessagesScreen> createState() => _AdvisorMessagesScreenState();
}

class _AdvisorMessagesScreenState extends State<AdvisorMessagesScreen> {
  PackageService? _packageService;
  UserModel? _currentUser;
  List<_ConversationItem> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final authService = await AuthService.getInstance();
      _currentUser = authService.currentUser;

      if (_currentUser == null || _currentUser!.id == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Initialize package service
      _packageService ??= await PackageService.getInstance();

      // Get all packages created by this advisor
      final packages = await _packageService!.getAdvisorPackages(_currentUser!.id!);

      // For each package, get all messages and group by traveler
      final conversationsMap = <String, _ConversationItem>{};
      final mongoService = await MongoDBService.getInstance();
      final usersCollection = mongoService.getUsersCollection();

      for (final package in packages) {
        if (package.id == null) continue;
        
        final messages = await _packageService!.getPackageMessages(package.id!, _currentUser!.id!);

        if (messages.isEmpty) continue;

        // Group messages by traveler
        final travelerMessages = <String, List<PackageMessage>>{};
        for (final message in messages) {
          if (message.senderId != _currentUser!.id!) {
            travelerMessages.putIfAbsent(message.senderId, () => []).add(message);
          }
        }

        // Create conversation items for each traveler
        for (final entry in travelerMessages.entries) {
          final travelerId = entry.key;
          final msgs = entry.value;
          final lastMessage = msgs.reduce((a, b) => 
            a.timestamp.isAfter(b.timestamp) ? a : b
          );
          final unreadCount = msgs.where((m) => !m.isRead).length;

          // Get traveler name from database
          String travelerName = 'Unknown User';
          try {
            final travelerDoc = await usersCollection.findOne({'_id': travelerId});
            if (travelerDoc != null) {
              travelerName = travelerDoc['fullName'] as String? ?? 'Unknown User';
            }
          } catch (e) {
            print('Error fetching traveler name: $e');
          }

          final key = '${package.id}_$travelerId';
          conversationsMap[key] = _ConversationItem(
            packageId: package.id!,
            packageTitle: package.title,
            travelerId: travelerId,
            travelerName: travelerName,
            lastMessage: lastMessage.message,
            lastMessageTime: lastMessage.timestamp,
            unreadCount: unreadCount,
            packageImage: package.images.isNotEmpty ? package.images.first : null,
          );
        }
      }

      // Sort by last message time (newest first)
      final sortedConversations = conversationsMap.values.toList()
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      setState(() {
        _conversations = sortedConversations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading conversations: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(AppConfig.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      return _buildConversationCard(_conversations[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Messages Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(AppConfig.textPrimaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When travelers message you about\nyour packages, they will appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(_ConversationItem conversation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(AppConfig.textSecondaryColor).withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: () => _openChat(conversation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: conversation.packageImage != null
                    ? Image.network(
                        conversation.packageImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
                      )
                    : _buildDefaultThumbnail(),
              ),
              const SizedBox(width: 12),
              // Conversation details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Traveler name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.travelerName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(AppConfig.textPrimaryColor),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(AppConfig.primaryColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Package title
                    Text(
                      'Re: ${conversation.packageTitle}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(AppConfig.primaryColor),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Last message
                    Text(
                      conversation.lastMessage,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Color(AppConfig.textSecondaryColor),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Timestamp
                    Text(
                      _formatTimestamp(conversation.lastMessageTime),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Color(AppConfig.textSecondaryColor),
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

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Color(AppConfig.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image,
        color: Color(AppConfig.primaryColor).withOpacity(0.5),
        size: 30,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Future<void> _openChat(_ConversationItem conversation) async {
    try {
      _packageService ??= await PackageService.getInstance();
      
      // Get package details
      final package = await _packageService!.getPackageById(conversation.packageId);
      
      if (package == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Package not found')),
          );
        }
        return;
      }

      // Get traveler details
      final mongoService = await MongoDBService.getInstance();
      final usersCollection = mongoService.getUsersCollection();
      final travelerDoc = await usersCollection.findOne({'_id': conversation.travelerId});
      
      if (travelerDoc == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Traveler not found')),
          );
        }
        return;
      }

      final traveler = UserModel.fromJson(travelerDoc);

      // Navigate to chat screen
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PackageChatScreen(
              packageId: conversation.packageId,
              advisor: traveler, // Passing traveler as the other party
              package: package,
            ),
          ),
        );

        // Reload conversations when returning
        _loadConversations();
      }
    } catch (e) {
      print('Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _ConversationItem {
  final String packageId;
  final String packageTitle;
  final String travelerId;
  final String travelerName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? packageImage;

  _ConversationItem({
    required this.packageId,
    required this.packageTitle,
    required this.travelerId,
    required this.travelerName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.packageImage,
  });
}
