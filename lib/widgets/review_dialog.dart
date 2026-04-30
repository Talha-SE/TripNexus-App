import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/blockchain_service.dart';
import '../services/mongodb_service.dart';

// Helper function to extract hex string from ObjectId format
String _extractHexString(String id) {
  final match = RegExp(r'ObjectId\("([0-9a-fA-F]{24})"\)').firstMatch(id);
  if (match != null) {
    return match.group(1)!;
  }
  return id;
}

class ReviewDialog extends StatefulWidget {
  final String packageId;
  final String packageName;
  final String bookingId;
  final VoidCallback onSuccess;

  const ReviewDialog({
    super.key,
    required this.packageId,
    required this.packageName,
    required this.bookingId,
    required this.onSuccess,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _txHash;

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a comment')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      print('📱 ReviewDialog: Getting BlockchainService instance...');
      final blockchainService = await BlockchainService.getInstance();
      print('✅ ReviewDialog: BlockchainService instance obtained');

      // Submit to blockchain
      print('📱 ReviewDialog: Calling addReview...');
      final txHash = await blockchainService.addReview(
        widget.packageId,
        _rating,
        _commentController.text.trim(),
      );
      print('✅ ReviewDialog: Review submitted successfully. TxHash: $txHash');

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _txHash = txHash;
        });

        // Mark booking as reviewed in MongoDB and store searchable review metadata.
        try {
          final mongoService = await MongoDBService.getInstance();
          final authService = await AuthService.getInstance();
          final currentUser = authService.currentUser;
          final bookingsCollection = mongoService
              .getPackageBookingsCollection();
          final reviewsCollection = mongoService
              .getBlockchainReviewsCollection();
          final bookingHexId = _extractHexString(widget.bookingId);
          final bookingObjectId = mongo.ObjectId.fromHexString(bookingHexId);
          final bookingDoc = await bookingsCollection.findOne({
            '_id': bookingObjectId,
          });
          final nowIso = DateTime.now().toIso8601String();

          await bookingsCollection.updateOne(
            {'_id': bookingObjectId},
            {
              r'$set': {'reviewSubmitted': true, 'reviewSubmittedAt': nowIso},
            },
          );

          await reviewsCollection.updateOne(
            {'bookingId': bookingHexId},
            {
              r'$set': {
                'bookingId': bookingHexId,
                'packageId': widget.packageId,
                'packageName': widget.packageName,
                'advisorId': bookingDoc?['advisorId']?.toString(),
                'travelerId':
                    currentUser?.id ?? bookingDoc?['travelerId']?.toString(),
                'travelerName': currentUser?.fullName ?? 'Traveler',
                'rating': _rating,
                'comment': _commentController.text.trim(),
                'txHash': txHash,
                'source': 'polygon',
                'createdAt': bookingDoc?['reviewSubmittedAt'] ?? nowIso,
                'updatedAt': nowIso,
              },
            },
            upsert: true,
          );

          print('✅ Booking marked as reviewed in MongoDB');
        } catch (e) {
          print('⚠️ Warning: Could not update booking review status: $e');
          // Don't fail the whole operation if MongoDB update fails
        }

        // Success! Dialog stays open until user closes it manually
      }
    } catch (e, stackTrace) {
      print('❌ ReviewDialog: Error submitting review: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Blockchain Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogWidth = math.min(
      MediaQuery.of(context).size.width * 0.92,
      520.0,
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark
          ? const Color(0xFF1E2430)
          : const Color(0xFFFDFEFF),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leave a Review',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDark ? Colors.white : const Color(0xFF0E1B34),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.packageName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.8)
                  : Color(AppConfig.textSecondaryColor),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: _txHash != null
            ? _buildSuccessState()
            : _isSubmitting
            ? _buildSubmittingState()
            : _buildInputState(isDark),
      ),
      actions: _isSubmitting
          ? []
          : _txHash != null
          ? [
              ElevatedButton.icon(
                onPressed: () {
                  widget.onSuccess();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  'Close',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConfig.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Submit to Blockchain',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
    );
  }

  Widget _buildInputState(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Blockchain badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.security_rounded,
                  size: 16,
                  color: Colors.purple.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Stored permanently on Polygon blockchain',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: List.generate(5, (index) {
              final isSelected = index < _rating;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _rating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: isSelected
                        ? const Color(0xFFFFC107)
                        : Colors.amber.withOpacity(0.45),
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              helperText: 'Your review will be visible to everyone',
              helperStyle: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              helperMaxLines: 2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        // Animated blockchain icon
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1500),
          builder: (context, double value, child) {
            return Transform.rotate(
              angle: value * 2 * 3.14159,
              child: Icon(
                Icons.account_tree_rounded,
                color: Color(
                  AppConfig.primaryColor,
                ).withOpacity(0.7 + (value * 0.3)),
                size: 48 + (value * 12),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Submitting to Blockchain...',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_rounded, size: 16, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Text(
                'Polygon Amoy Testnet',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const LinearProgressIndicator(),
        const SizedBox(height: 12),
        Text(
          'Signing transaction with Web3...',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    final explorerUrl = 'https://amoy.polygonscan.com/tx/$_txHash';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Animated success icon
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Success! 🎉',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your review is now permanently stored on the blockchain',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Blockchain details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                // Network badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Polygon Amoy Testnet',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transaction hash
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Hash:',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _txHash!.length > 20
                                  ? '${_txHash!.substring(0, 10)}...${_txHash!.substring(_txHash!.length - 10)}'
                                  : _txHash!,
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 11,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _txHash!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaction hash copied!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // View on blockchain explorer button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(explorerUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(
                      'View on PolygonScan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Transaction propagation notice
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Transaction may take 10-30 seconds to appear on explorer',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'This review is immutable and transparent',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.blue.shade700,
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
