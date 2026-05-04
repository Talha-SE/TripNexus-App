import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import 'formatted_text.dart';

class TripPlanView extends StatelessWidget {
  final String destination;
  final int duration;
  final String interests;
  final String? budget;
  final String planText;

  const TripPlanView({
    super.key,
    required this.destination,
    required this.duration,
    required this.interests,
    required this.planText,
    this.budget,
  });

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
    String? title,
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
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildHeroStat(Icons.calendar_today_rounded, '$duration Days'),
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

  Widget _buildSectionCard(
    BuildContext context,
    _PlanSection section, {
    required bool isDark,
    required Color primaryColor,
  }) {
    final icon = _iconForSection(section.title);
    final accentColor = _sectionAccentColor(section.title, primaryColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Side accent line
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.7),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentColor.withOpacity(0.1)),
                        ),
                        child: Icon(icon, color: accentColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          section.title,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: FormattedText(
                    text: section.lines.join('\n'),
                    fontSize: 15,
                    textColor: isDark ? Colors.white.withOpacity(0.8) : Colors.grey.shade800,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryColor, primaryColor.withOpacity(0.5)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Full Schedule',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        ...days.asMap().entries.map((entry) {
          return _buildDayItem(
            entry.value,
            dayNumber: entry.key + 1,
            isLast: entry.key == days.length - 1,
            isDark: isDark,
            primaryColor: primaryColor,
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
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 12),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withBlue(255).withRed(100)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'D$dayNumber',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            primaryColor.withOpacity(0.4),
                            primaryColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (day.morning.isNotEmpty)
                      _buildTimeRow(
                        'Morning',
                        day.morning,
                        Icons.wb_sunny_rounded,
                        const Color(0xFFF59E0B),
                        isDark,
                      ),
                    if (day.afternoon.isNotEmpty)
                      _buildTimeRow(
                        'Afternoon',
                        day.afternoon,
                        Icons.wb_cloudy_rounded,
                        const Color(0xFF3B82F6),
                        isDark,
                      ),
                    if (day.evening.isNotEmpty)
                      _buildTimeRow(
                        'Evening',
                        day.evening,
                        Icons.nights_stay_rounded,
                        const Color(0xFF6366F1),
                        isDark,
                      ),
                    if (day.tips.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                day.tips.join(' '),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isDark ? Colors.amber.shade100 : Colors.amber.shade900,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    String label,
    List<String> activities,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                ...activities.map((activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          activity,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDark ? Colors.white.withOpacity(0.85) : Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
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
    return text.replaceAll('**', '').replaceAll('*', '').trim();
  }

  List<_DayPlan> _parseDays(List<String> lines) {
    final days = <_DayPlan>[];
    _DayPlan? current;
    String currentBlock = 'misc';

    void commit() {
      if (current != null) {
        days.add(current!);
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('###') || (line.startsWith('**Day') && line.contains('**'))) {
        commit();
        final title = _stripMarkdown(line.replaceFirst(RegExp(r'^###\s*'), '').trim());
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
      if (line.startsWith('✨') || line.toLowerCase().contains('tip') || line.contains('Hidden Gem')) {
        current?.tips.add(rawLine);
        continue;
      }

      if (current == null) continue;

      final cleanLine = _stripMarkdown(rawLine).replaceFirst(RegExp(r'^[-*]\s*'), '');
      if (cleanLine.isEmpty) continue;

      if (currentBlock == 'morning') {
        current.morning.add(cleanLine);
      } else if (currentBlock == 'afternoon') {
        current.afternoon.add(cleanLine);
      } else if (currentBlock == 'evening') {
        current.evening.add(cleanLine);
      } else {
        current.misc.add(cleanLine);
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
  final List<String> misc = [];
  final List<String> tips = [];

  _DayPlan({required this.title});
}
