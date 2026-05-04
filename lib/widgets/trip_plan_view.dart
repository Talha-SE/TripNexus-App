import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import 'formatted_text.dart';
import '../services/openverse_image_service.dart';

class TripPlanView extends StatefulWidget {
  final String destination;
  final int duration;
  final DateTime? startDate;
  final DateTime? endDate;
  final String interests;
  final String? budget;
  final String planText;

  const TripPlanView({
    super.key,
    required this.destination,
    required this.duration,
    this.startDate,
    this.endDate,
    required this.interests,
    required this.planText,
    this.budget,
  });

  @override
  State<TripPlanView> createState() => _TripPlanViewState();
}

class _TripPlanViewState extends State<TripPlanView> {
  int? _expandedDayIndex;
  final OpenverseImageService _imageService = OpenverseImageService();
  final Map<int, OpenverseImageAsset?> _dayImages = {};
  final Map<String, OpenverseImageAsset?> _sectionImages = {};
  OpenverseImageAsset? _heroImage;
  bool _loadingVisualAssets = false;

  String get destination => widget.destination;
  int get duration => widget.duration;
  DateTime? get startDate => widget.startDate;
  DateTime? get endDate => widget.endDate;
  String get interests => widget.interests;
  String? get budget => widget.budget;
  String get planText => widget.planText;

  String get tripWindowLabel {
    if (startDate == null || endDate == null) return 'Flexible dates';
    return '${DateFormat('MMM dd').format(startDate!)} - ${DateFormat('MMM dd').format(endDate!)}';
  }

  @override
  void initState() {
    super.initState();
    _refreshVisualAssets();
  }

  @override
  void didUpdateWidget(covariant TripPlanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planText != widget.planText ||
        oldWidget.destination != widget.destination ||
        oldWidget.interests != widget.interests) {
      _refreshVisualAssets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Color(AppConfig.primaryColor);
    final parsed = _parsePlan(planText);
    final sections = parsed.sections.isEmpty
        ? [
            _PlanSection(
              title: 'Trip Plan',
              lines: planText.split('\n'),
            ),
          ]
        : parsed.sections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroCard(
          context,
          isDark: isDark,
          primaryColor: primaryColor,
          title: parsed.title,
          sectionCount: sections.length,
          imageAsset: _heroImage,
          tripWindow: tripWindowLabel,
        ),
        const SizedBox(height: 18),
        _buildPlanSummaryCard(
          context,
          isDark: isDark,
          primaryColor: primaryColor,
          sectionCount: sections.length,
        ),
        const SizedBox(height: 24),
        ...sections.map((section) {
          if (_isItinerarySection(section.title)) {
            return _buildItinerarySection(
              context,
              section,
              isDark: isDark,
              primaryColor: primaryColor,
            );
          }

          return _buildSectionCard(
            context,
            section,
            isDark: isDark,
            primaryColor: primaryColor,
            imageAsset: _sectionImages[section.title],
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required bool isDark,
    required Color primaryColor,
    required int sectionCount,
    OpenverseImageAsset? imageAsset,
    String? title,
    String? tripWindow,
  }) {
    final titleText = title?.isNotEmpty == true ? title! : 'Your Trip Plan';
    final heroStart = isDark ? const Color(0xFF1E293B) : primaryColor;
    final heroEnd = isDark ? const Color(0xFF0F172A) : primaryColor.withBlue(255).withRed(30);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [heroStart, heroEnd],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isDark ? 0.3 : 0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageAsset != null
                  ? Image.network(
                      imageAsset.thumbnailUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) => _buildImageFallback(destination),
                    )
                  : _buildImageFallback(destination),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.72),
                    ],
                  ),
                ),
              ),
            ),
            // Decorative shapes
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'AI CRAFTED JOURNEY',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    destination,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    titleText,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (imageAsset != null)
                    _buildImageCaption(
                      title: imageAsset.title,
                      creator: imageAsset.creator,
                      license: imageAsset.license,
                    ),
                  if (imageAsset != null) const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildHeroStat(Icons.calendar_today_rounded, '$duration Days'),
                        _buildHeroStat(Icons.date_range_rounded, tripWindow ?? tripWindowLabel),
                      _buildHeroStat(Icons.view_agenda_rounded, '$sectionCount Sections'),
                      if (budget != null && budget!.isNotEmpty)
                        _buildHeroStat(Icons.payments_rounded, budget!),
                      _buildHeroStat(Icons.insights_rounded, 'Personalized'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummaryCard(
    BuildContext context, {
    required bool isDark,
    required Color primaryColor,
    required int sectionCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C31) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.75)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Snapshot',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Quick controls for the generated itinerary',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSummaryChip(Icons.place_rounded, destination, primaryColor, isDark),
              _buildSummaryChip(Icons.calendar_month_rounded, '$duration days', const Color(0xFF3B82F6), isDark),
              _buildSummaryChip(Icons.date_range_rounded, tripWindowLabel, const Color(0xFF0EA5E9), isDark),
              _buildSummaryChip(Icons.layers_rounded, '$sectionCount sections', const Color(0xFF8B5CF6), isDark),
              _buildSummaryChip(Icons.favorite_rounded, interests, const Color(0xFFEF4444), isDark),
              if (budget != null && budget!.isNotEmpty)
                _buildSummaryChip(Icons.payments_rounded, budget!, const Color(0xFF10B981), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedImageCard(
    OpenverseImageAsset? imageAsset, {
    String? fallbackLabel,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: imageAsset != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageAsset.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImageFallback(fallbackLabel),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.56),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _buildImageCaption(
                      title: imageAsset.title,
                      creator: imageAsset.creator,
                      license: imageAsset.license,
                      compact: true,
                    ),
                  ),
                ],
              )
            : _buildImageFallback(fallbackLabel),
      ),
    );
  }

  Widget _buildImageFallback(String? fallbackLabel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: Colors.grey.shade500,
              size: 34,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                fallbackLabel != null && fallbackLabel.isNotEmpty
                    ? 'Searching images for $fallbackLabel'
                    : 'Searching open images',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCaption({
    required String title,
    required String creator,
    required String license,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 7 : 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(compact ? 0.45 : 0.38),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Icon(Icons.photo_library_outlined, color: Colors.white, size: 12),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$title · $creator · $license',
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshVisualAssets() async {
    if (_loadingVisualAssets || !mounted) return;

    final parsed = _parsePlan(planText);
    final sections = parsed.sections;
    final itinerarySection = sections.where((section) => _isItinerarySection(section.title)).toList();
    final days = itinerarySection.isNotEmpty ? _parseDays(itinerarySection.first.lines) : const <_DayPlan>[];

    setState(() => _loadingVisualAssets = true);

    final nextDayImages = <int, OpenverseImageAsset?>{};
    final nextSectionImages = <String, OpenverseImageAsset?>{};

    final heroQuery = _cleanImageQuery('$destination travel highlights $interests') ?? destination;
    final heroFuture = _imageService.searchBestImage(heroQuery, fallbackQuery: destination);

    final dayFutures = <Future<void>>[];
    for (var index = 0; index < days.length; index++) {
      final dayNumber = index + 1;
      final query = _buildDayImageQuery(days[index]);
      dayFutures.add(
        _imageService.searchBestImage(query, fallbackQuery: destination).then((asset) {
          nextDayImages[dayNumber] = asset;
        }),
      );
    }

    final sectionFutures = <Future<void>>[];
    for (final section in sections) {
      if (!_shouldFetchSectionImage(section.title)) continue;
      final query = _buildSectionImageQuery(section);
      sectionFutures.add(
        _imageService.searchBestImage(query, fallbackQuery: '$destination ${section.title}').then((asset) {
          nextSectionImages[section.title] = asset;
        }),
      );
    }

    final heroAsset = await heroFuture;
    await Future.wait([...dayFutures, ...sectionFutures]);

    if (!mounted) return;
    setState(() {
      _heroImage = heroAsset;
      _dayImages
        ..clear()
        ..addAll(nextDayImages);
      _sectionImages
        ..clear()
        ..addAll(nextSectionImages);
      _loadingVisualAssets = false;
    });
  }

  bool _shouldFetchSectionImage(String title) {
    final lower = title.toLowerCase();
    return lower.contains('culinary') || lower.contains('food') || lower.contains('dining') || lower.contains('overview');
  }

  String _buildDayImageQuery(_DayPlan day) {
    final preferredSource = day.evening.isNotEmpty
        ? day.evening.first
        : day.morning.isNotEmpty
            ? day.morning.first
            : day.afternoon.isNotEmpty
                ? day.afternoon.first
                : day.title;
    final cleanedSource = _cleanImageQuery(preferredSource);
    final cleanedTitle = _cleanImageQuery(day.title);
    return [destination, cleanedTitle, cleanedSource].where((part) => part != null && part.isNotEmpty).join(' ');
  }

  String _buildSectionImageQuery(_PlanSection section) {
    final contentSeed = section.lines.take(4).join(' ');
    final cleanedSeed = _cleanImageQuery(contentSeed);
    final cleanedTitle = _cleanImageQuery(section.title);
    return [destination, cleanedTitle, cleanedSeed].where((part) => part != null && part.isNotEmpty).join(' ');
  }

  String? _cleanImageQuery(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'[\*#_`\[\]\(\)]'), ' ')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return null;

    final parts = cleaned.split(' ');
    final limited = parts.take(8).join(' ');
    return limited.isEmpty ? null : limited;
  }

  Widget _buildSectionCard(
    BuildContext context,
    _PlanSection section, {
    required bool isDark,
    required Color primaryColor,
    OpenverseImageAsset? imageAsset,
  }) {
    final icon = _iconForSection(section.title);
    final accentColor = _sectionAccentColor(section.title, primaryColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accentColor, accentColor.withOpacity(0.5)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
                ),
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.15),
                              accentColor.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withOpacity(0.2),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(icon, color: accentColor, size: 26),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: GoogleFonts.outfit(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 40,
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [accentColor, accentColor.withOpacity(0.3)],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Image if available
                if (imageAsset != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 0, 26, 22),
                    child: _buildFixedImageCard(imageAsset),
                  ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 0, 26, 28),
                  child: FormattedText(
                    text: section.lines.map(_sanitizePlanLine).where((line) => !_isJunkLine(line)).join('\n'),
                    fontSize: 14,
                    textColor: isDark ? Colors.white.withOpacity(0.85) : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItinerarySection(
    BuildContext context,
    _PlanSection section, {
    required bool isDark,
    required Color primaryColor,
  }) {
    final days = _parseDays(section.lines);
    if (days.isEmpty) {
      return _buildSectionCard(context, section, isDark: isDark, primaryColor: primaryColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium header
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 16, 8, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent bar
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primaryColor, primaryColor.withOpacity(0.5)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR JOURNEY',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Full Schedule',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Experience your ${days.length}-day adventure with carefully curated activities',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        
        // Days timeline
        ...days.asMap().entries.map((entry) {
          return _buildDayItem(
            entry.value,
            dayNumber: entry.key + 1,
            isLast: entry.key == days.length - 1,
            isDark: isDark,
            primaryColor: primaryColor,
            imageAsset: _dayImages[entry.key + 1],
          );
        }),
      ],
    );
  }

  Widget _buildDayItem(
    _DayPlan day, {
    required int dayNumber,
    required bool isLast,
    required bool isDark,
    required Color primaryColor,
    OpenverseImageAsset? imageAsset,
  }) {
    final expanded = _expandedDayIndex == dayNumber;
    final summaryLine = day.morning.isNotEmpty
        ? day.morning.first
        : day.afternoon.isNotEmpty
            ? day.afternoon.first
            : day.evening.isNotEmpty
                ? day.evening.first
                : day.misc.isNotEmpty
                    ? day.misc.first
                    : 'Tap to reveal the full plan for this day.';
    
    // Extract pricing from activities
    final estimatedPrice = _extractPricing(day);

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header with number and info
          Padding(
            padding: const EdgeInsets.only(bottom: 14, left: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated day number circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: expanded
                          ? [primaryColor, primaryColor.withOpacity(0.6)]
                          : [primaryColor, primaryColor.withOpacity(0.75)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(expanded ? 0.45 : 0.35),
                        blurRadius: expanded ? 18 : 12,
                        offset: Offset(0, expanded ? 8 : 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Day $dayNumber',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  day.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    letterSpacing: -0.3,
                                  ),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Pricing badge
                          if (estimatedPrice.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF10B981).withOpacity(0.12),
                                    const Color(0xFF059669).withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withOpacity(0.25),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Est. Cost',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF10B981),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    estimatedPrice,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF10B981),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main card
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111C31) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: expanded
                    ? primaryColor.withOpacity(0.35)
                    : isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                  blurRadius: expanded ? 28 : 18,
                  offset: Offset(0, expanded ? 12 : 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  setState(() {
                    _expandedDayIndex = expanded ? null : dayNumber;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildFixedImageCard(imageAsset, fallbackLabel: day.title),
                    ),
                    const SizedBox(height: 22),
                    
                    // Activity stats
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (day.morning.isNotEmpty)
                          _buildActivityStatChip(
                            Icons.wb_sunny_rounded,
                            '${day.morning.length}',
                            'Morning',
                            const Color(0xFFF59E0B),
                            isDark,
                          ),
                        if (day.afternoon.isNotEmpty)
                          _buildActivityStatChip(
                            Icons.wb_cloudy_rounded,
                            '${day.afternoon.length}',
                            'Afternoon',
                            const Color(0xFF3B82F6),
                            isDark,
                          ),
                        if (day.evening.isNotEmpty)
                          _buildActivityStatChip(
                            Icons.nights_stay_rounded,
                            '${day.evening.length}',
                            'Evening',
                            const Color(0xFF6366F1),
                            isDark,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Summary
                    Text(
                      summaryLine.replaceAll(RegExp(r'\(.*?\)'), '').trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: expanded ? null : 2,
                      overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                    
                    // Expand indicator
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Expanded content
                    AnimatedCrossFade(
                      firstChild: const SizedBox(height: 0),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Divider
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.15),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Activities by time
                            if (day.morning.isNotEmpty)
                              _buildTimeRowHorizontal(
                                'Morning',
                                day.morning,
                                Icons.wb_sunny_rounded,
                                const Color(0xFFF59E0B),
                                isDark,
                              ),
                            if (day.afternoon.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 22),
                                child: _buildTimeRowHorizontal(
                                  'Afternoon',
                                  day.afternoon,
                                  Icons.wb_cloudy_rounded,
                                  const Color(0xFF3B82F6),
                                  isDark,
                                ),
                              ),
                            if (day.evening.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 22),
                                child: _buildTimeRowHorizontal(
                                  'Evening',
                                  day.evening,
                                  Icons.nights_stay_rounded,
                                  const Color(0xFF6366F1),
                                  isDark,
                                ),
                              ),
                            
                            if (day.budget.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: day.budget
                                      .map(
                                        (item) => _buildSummaryChip(
                                          Icons.account_balance_wallet_rounded,
                                          item,
                                          const Color(0xFF10B981),
                                          isDark,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),

                            // Tips
                            if (day.tips.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 22),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.withOpacity(0.12),
                                        Colors.amber.withOpacity(0.06),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.amber.withOpacity(0.2),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.lightbulb_rounded,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Insider Tips',
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              day.tips.map(_sanitizePlanLine).where((line) => line.isNotEmpty).join(' '),
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.amber.shade100
                                                    : Colors.amber.shade900,
                                                fontWeight: FontWeight.w500,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      crossFadeState:
                          expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                      firstCurve: Curves.easeOut,
                      secondCurve: Curves.easeOutCubic,
                      sizeCurve: Curves.easeOutCubic,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Vertical connector
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(left: 25, top: 16),
              child: SizedBox(
                width: 2,
                height: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor.withOpacity(0.4),
                        primaryColor.withOpacity(0.08),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityStatChip(
    IconData icon,
    String count,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _extractPricing(_DayPlan day) {
    final allActivities = [
      ...day.morning,
      ...day.afternoon,
      ...day.evening,
      ...day.misc,
    ];
    
    final pricePattern = RegExp(r'\(\s*[\$£€₹]\s*[\d,.]+(?:\s*[-–]\s*[\d,.]+)?\s*\)');
    final matches = pricePattern.allMatches(allActivities.join(' '));
    
    if (matches.isEmpty) return '';
    
    // Extract all prices and try to sum them up
    final prices = <String>[];
    for (final match in matches) {
      prices.add(match.group(0)?.replaceAll(RegExp(r'[()\\s]'), '') ?? '');
    }
    
    if (prices.isEmpty) return '';
    return prices.first;
  }

  Widget _buildTimeRowHorizontal(
    String label,
    List<String> activities,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final filteredActivities = activities.where(_isRenderableActivity).map(_sanitizePlanLine).where((line) => line.isNotEmpty).toList();
    if (filteredActivities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '${filteredActivities.length} activit${filteredActivities.length == 1 ? 'y' : 'ies'}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Column(
          children: filteredActivities.asMap().entries.map((entry) {
            final activity = entry.value;
            final isLast = entry.key == filteredActivities.length - 1;
            final activityIcon = _getActivityIcon(activity);
            final cleanActivity = _sanitizePlanLine(activity.replaceAll(RegExp(r'\(.*?\)'), '').trim());

            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2332) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withOpacity(0.22),
                                color.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(activityIcon, color: color, size: 19),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${entry.key + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cleanActivity,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark ? Colors.white.withOpacity(0.92) : Colors.grey.shade800,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getActivityIcon(String activity) {
    final lower = activity.toLowerCase();
    if (lower.contains('museum') || lower.contains('gallery') || lower.contains('art')) return Icons.palette_rounded;
    if (lower.contains('eat') || lower.contains('lunch') || lower.contains('dine') || lower.contains('restaurant') || lower.contains('food') || lower.contains('dinner')) return Icons.restaurant_rounded;
    if (lower.contains('walk') || lower.contains('explore') || lower.contains('stroll')) return Icons.directions_walk_rounded;
    if (lower.contains('shop') || lower.contains('market') || lower.contains('store')) return Icons.shopping_bag_rounded;
    if (lower.contains('park') || lower.contains('nature') || lower.contains('garden')) return Icons.park_rounded;
    if (lower.contains('monument') || lower.contains('historic') || lower.contains('temple') || lower.contains('church')) return Icons.castle_rounded;
    if (lower.contains('beach') || lower.contains('water') || lower.contains('swim')) return Icons.water_rounded;
    if (lower.contains('adventure') || lower.contains('hike') || lower.contains('trek')) return Icons.terrain_rounded;
    if (lower.contains('show') || lower.contains('theater') || lower.contains('concert') || lower.contains('entertainment')) return Icons.theater_comedy_rounded;
    if (lower.contains('relax') || lower.contains('spa') || lower.contains('rest')) return Icons.spa_rounded;
    return Icons.location_on_rounded;
  }

  Color _sectionAccentColor(String title, Color primaryColor) {
    final lower = title.toLowerCase();
    if (lower.contains('overview')) return const Color(0xFF3B82F6);
    if (lower.contains('itinerary')) return const Color(0xFF8B5CF6);
    if (lower.contains('culinary') || lower.contains('food')) return const Color(0xFFEF4444);
    if (lower.contains('transport')) return const Color(0xFF10B981);
    if (lower.contains('budget') || lower.contains('investment')) return const Color(0xFFF59E0B);
    if (lower.contains('advice') || lower.contains('tips')) return const Color(0xFF6366F1);
    if (lower.contains('sustainable')) return const Color(0xFF06B6D4);
    return primaryColor;
  }

  IconData _iconForSection(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('overview')) return Icons.explore_rounded;
    if (lower.contains('culinary') || lower.contains('food')) return Icons.restaurant_menu_rounded;
    if (lower.contains('transport')) return Icons.directions_bus_filled_rounded;
    if (lower.contains('budget') || lower.contains('investment')) return Icons.account_balance_wallet_rounded;
    if (lower.contains('advice') || lower.contains('tips')) return Icons.lightbulb_outline_rounded;
    if (lower.contains('sustainable')) return Icons.eco_rounded;
    return Icons.auto_awesome_motion_rounded;
  }

  bool _isItinerarySection(String title) {
    final lower = title.toLowerCase();
    return lower.contains('itinerary') || lower.contains('schedule') || lower.contains('plan');
  }

  _PlanParse _parsePlan(String text) {
    final lines = text.split('\n');
    final sections = <_PlanSection>[];
    String? title;
    String? currentTitle;
    final currentLines = <String>[];

    void commit() {
      if (currentTitle != null) {
        sections.add(
          _PlanSection(
            title: _stripMarkdown(currentTitle),
            lines: List<String>.from(currentLines),
          ),
        );
        currentLines.clear();
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        if (currentTitle != null && currentLines.isNotEmpty) {
          currentLines.add('');
        }
        continue;
      }

      if (line.startsWith('#')) {
        final headingLevel = _countHeadingLevel(line);
        final headingText = _stripMarkdown(line.replaceFirst(RegExp(r'^#+\s*'), '').trim());

        if (headingLevel == 1) {
          title = headingText;
          continue;
        }

        if (headingLevel == 2) {
          commit();
          currentTitle = headingText;
          continue;
        }
      }

      if (currentTitle != null) {
        currentLines.add(rawLine);
      }
    }

    commit();
    return _PlanParse(title: title, sections: sections);
  }

  int _countHeadingLevel(String line) {
    int level = 0;
    for (int i = 0; i < line.length; i++) {
      if (line[i] == '#') {
        level++;
      } else {
        break;
      }
    }
    return level;
  }

  String _stripMarkdown(String text) {
    var cleaned = text
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'`[^`]*`'), ' ')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll(RegExp(r'^\s*[-•]\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }

    return cleaned;
  }

  String _sanitizePlanLine(String text) {
    final cleaned = _stripMarkdown(text)
        .replaceAll(RegExp(r'\[(Repeat|Optional|Example).*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r"\bInstance of\s+'[^']+'"), '')
        .trim();

    if (cleaned == '--' || cleaned == '-' || cleaned == '...') return '';
    return cleaned;
  }

  bool _isJunkLine(String text) {
    final value = text.trim();
    if (value.isEmpty) return true;
    if (value == '--' || value == '-' || value == '...') return true;
    final lowered = value.toLowerCase();
    if (lowered.contains('instance of _dayplan')) return true;
    if (lowered.startsWith('repeat the same day-card structure')) return true;
    return false;
  }

  bool _isRenderableActivity(String line) {
    final value = _sanitizePlanLine(line);
    if (value.isEmpty || _isJunkLine(value)) return false;

    final lower = value.toLowerCase();
    if (lower.startsWith('budget')) return false;
    if (lower.startsWith('tip')) return false;
    if (lower.contains('total estimated cost')) return false;
    if (lower.contains('daily budget')) return false;
    return true;
  }

  List<_DayPlan> _parseDays(List<String> lines) {
    final days = <_DayPlan>[];
    _DayPlan? current;
    String currentBlock = 'misc';

    void commit() {
      final day = current;
      if (day != null) {
        days.add(day);
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('###') || (line.startsWith('**Day') && line.contains('**'))) {
        commit();
        final title = _sanitizePlanLine(line.replaceFirst(RegExp(r'^###\s*'), '').trim());
        current = _DayPlan(title: title);
        currentBlock = 'misc';
        continue;
      }

      if (line.toLowerCase().contains('morning')) {
        currentBlock = 'morning';
        continue;
      }
      if (line.toLowerCase().contains('afternoon')) {
        currentBlock = 'afternoon';
        continue;
      }
      if (line.toLowerCase().contains('evening') || line.toLowerCase().contains('night')) {
        currentBlock = 'evening';
        continue;
      }
      if (line.toLowerCase().contains('budget')) {
        currentBlock = 'budget';
        continue;
      }
      if (line.toLowerCase().contains('tip') || line.contains('Hidden Gem')) {
        currentBlock = 'tip';
        continue;
      }
      if (line.startsWith('✨') || line.startsWith('💡')) {
        final tipLine = _sanitizePlanLine(rawLine).replaceFirst(RegExp(r'^(Tip|Tips?)\s*:\s*', caseSensitive: false), '');
        if (tipLine.isNotEmpty && !_isJunkLine(tipLine)) {
          current?.tips.add(tipLine);
        }
        continue;
      }

      if (current == null) continue;

      final cleanLine = _sanitizePlanLine(rawLine).replaceFirst(RegExp(r'^[-*]\s*'), '');
      if (cleanLine.isEmpty) continue;

      if (currentBlock == 'morning') {
        if (_isRenderableActivity(cleanLine)) current.morning.add(cleanLine);
      } else if (currentBlock == 'afternoon') {
        if (_isRenderableActivity(cleanLine)) current.afternoon.add(cleanLine);
      } else if (currentBlock == 'evening') {
        if (_isRenderableActivity(cleanLine)) current.evening.add(cleanLine);
      } else if (currentBlock == 'budget') {
        if (!_isJunkLine(cleanLine)) current.budget.add(cleanLine);
      } else if (currentBlock == 'tip') {
        final tipLine = cleanLine.replaceFirst(RegExp(r'^(Tip|Tips?)\s*:\s*', caseSensitive: false), '');
        if (!_isJunkLine(tipLine) && tipLine.isNotEmpty) current.tips.add(tipLine);
      } else {
        if (_isRenderableActivity(cleanLine)) current.misc.add(cleanLine);
      }
    }

    commit();
    return days;
  }
}

class _PlanParse {
  final String? title;
  final List<_PlanSection> sections;

  _PlanParse({required this.title, required this.sections});
}

class _PlanSection {
  final String title;
  final List<String> lines;

  _PlanSection({required this.title, required this.lines});
}

class _DayPlan {
  final String title;
  final List<String> morning = [];
  final List<String> afternoon = [];
  final List<String> evening = [];
  final List<String> budget = [];
  final List<String> misc = [];
  final List<String> tips = [];

  _DayPlan({required this.title});
}
