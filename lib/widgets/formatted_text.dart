import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class FormattedText extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color textColor;

  const FormattedText({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.textColor = Colors.black87,
  });

  @override
  State<FormattedText> createState() => _FormattedTextState();
}

class _FormattedTextState extends State<FormattedText> {
  final List<TapGestureRecognizer> _linkRecognizers = [];

  @override
  void dispose() {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();
    super.dispose();
  }

  void _resetRecognizers() {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();
  }

  TapGestureRecognizer _createLinkRecognizer(String url) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () async {
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      };
    _linkRecognizers.add(recognizer);
    return recognizer;
  }

  static final RegExp _urlPattern = RegExp(r'https?://[^\s]+');

  @override
  Widget build(BuildContext context) {
    _resetRecognizers();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseText(widget.text, context),
    );
  }

  List<Widget> _parseText(String text, BuildContext context) {
    final List<Widget> widgets = [];
    final lines = text.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Check for markdown headings (# ## ###)
      if (line.trim().startsWith('#')) {
        widgets.add(_buildMarkdownHeading(line));
        widgets.add(const SizedBox(height: 8));
      }
      // Check for special highlight/callout (✨, 💡, 📍, 💰)
      else if (line.trim().startsWith('✨') || line.trim().startsWith('💡') || line.trim().startsWith('💰') || line.trim().startsWith('🌱')) {
        widgets.add(_buildHighlightBox(line, context));
        widgets.add(const SizedBox(height: 12));
      }
      // Check for emoji headers (🏛️, 📍, etc.)
      else if (line.contains('**') && _hasEmoji(line)) {
        widgets.add(_buildHeader(line));
        widgets.add(const SizedBox(height: 8));
      }
      // Check for bullet points
      else if (line.trim().startsWith('•') || line.trim().startsWith('-') || line.trim().startsWith('*')) {
        widgets.add(_buildBulletPoint(line));
      }
      // Regular text with possible bold/italic
      else {
        widgets.add(_buildFormattedLine(line));
        widgets.add(const SizedBox(height: 4));
      }
    }

    return widgets;
  }

  bool _hasEmoji(String text) {
    final emojiPattern = RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true);
    return emojiPattern.hasMatch(text);
  }

  Widget _buildMarkdownHeading(String line) {
    int level = 0;
    String text = line;
    
    // Count # symbols
    while (text.startsWith('#')) {
      level++;
      text = text.substring(1);
    }
    
    text = text.trim();
    
    // Remove any bold markers
    text = text.replaceAll('**', '');
    
    double headingSize = widget.fontSize + (4 - level) * 2;
    if (headingSize < widget.fontSize) headingSize = widget.fontSize + 2;
    
    return Padding(
      padding: EdgeInsets.only(top: level == 1 ? 16 : 12, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: headingSize,
          fontWeight: level <= 2 ? FontWeight.bold : FontWeight.w600,
          color: widget.textColor,
        ),
      ),
    );
  }

  Widget _buildHighlightBox(String line, BuildContext context) {
    MaterialColor boxColor;
    Color contentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (line.contains('✨')) {
      boxColor = Colors.amber;
    } else if (line.contains('💡')) {
      boxColor = Colors.blue;
    } else if (line.contains('💰')) {
      boxColor = Colors.green;
    } else if (line.contains('🌱')) {
      boxColor = Colors.teal;
    } else {
      boxColor = Colors.grey;
    }

    contentColor = isDark ? boxColor.shade200 : boxColor.shade900;
    final bgColor = boxColor.withOpacity(isDark ? 0.15 : 0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: boxColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: RichText(
        text: _buildInlineFormattedSpan(line.trim(), contentColor),
      ),
    );
  }

  Widget _buildHeader(String line) {
    // Extract emoji and text
    final cleaned = line.replaceAll('**', '').trim();
    
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        cleaned,
        style: GoogleFonts.poppins(
          fontSize: widget.fontSize + 2,
          fontWeight: FontWeight.bold,
          color: widget.textColor,
        ),
      ),
    );
  }

  Widget _buildFormattedLine(String line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: _buildInlineFormattedSpan(line, widget.textColor),
      ),
    );
  }

  TextSpan _buildInlineFormattedSpan(String text, Color baseColor) {
    final spans = <InlineSpan>[];
    int currentIndex = 0;

    // Pattern to match both **bold** and *italic* (but not ** inside words)
    final boldPattern = RegExp(r'\*\*(.+?)\*\*');
    final italicPattern = RegExp(r'(?<!\*)\*(?!\*)(.+?)\*(?!\*)');

    // Find all bold and italic matches
    final allMatches = <_FormatMatch>[];
    
    for (final match in boldPattern.allMatches(text)) {
      allMatches.add(_FormatMatch(match.start, match.end, match.group(1)!, _FormatType.bold));
    }
    
    for (final match in italicPattern.allMatches(text)) {
      // Skip if this italic is part of a bold pattern
      bool isPartOfBold = false;
      for (final boldMatch in allMatches) {
        if (match.start >= boldMatch.start - 1 && match.end <= boldMatch.end + 1) {
          isPartOfBold = true;
          break;
        }
      }
      if (!isPartOfBold) {
        allMatches.add(_FormatMatch(match.start, match.end, match.group(1)!, _FormatType.italic));
      }
    }

    // Sort by start position
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    for (final formatMatch in allMatches) {
      // Add normal text before this match
      if (formatMatch.start > currentIndex) {
        _appendWithLinks(
          spans,
          text.substring(currentIndex, formatMatch.start),
          GoogleFonts.poppins(
            fontSize: widget.fontSize,
            color: baseColor,
          ),
        );
      }

      // Add formatted text
      _appendWithLinks(
        spans,
        formatMatch.text,
        GoogleFonts.poppins(
          fontSize: widget.fontSize,
          fontWeight: formatMatch.type == _FormatType.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: formatMatch.type == _FormatType.italic ? FontStyle.italic : FontStyle.normal,
          color: baseColor,
        ),
      );

      currentIndex = formatMatch.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      _appendWithLinks(
        spans,
        text.substring(currentIndex),
        GoogleFonts.poppins(
          fontSize: widget.fontSize,
          color: baseColor,
        ),
      );
    }

    return TextSpan(
      children: spans.isEmpty ? [
        TextSpan(
          text: text,
          style: GoogleFonts.poppins(
            fontSize: widget.fontSize,
            color: baseColor,
          ),
        ),
      ] : spans,
    );
  }

  void _appendWithLinks(List<InlineSpan> spans, String segment, TextStyle style) {
    if (segment.isEmpty) return;

    var currentIndex = 0;
    for (final match in _urlPattern.allMatches(segment)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: segment.substring(currentIndex, match.start),
          style: style,
        ));
      }

      var matchedUrl = match.group(0)!;
      var trailing = '';
      while (matchedUrl.isNotEmpty && RegExp(r'[),.;!?]$').hasMatch(matchedUrl)) {
        trailing = matchedUrl.substring(matchedUrl.length - 1) + trailing;
        matchedUrl = matchedUrl.substring(0, matchedUrl.length - 1);
      }

      if (matchedUrl.isNotEmpty) {
        spans.add(
          TextSpan(
            text: matchedUrl,
            style: style.copyWith(
              color: Colors.blue.shade700,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
            recognizer: _createLinkRecognizer(matchedUrl),
          ),
        );
      }

      if (trailing.isNotEmpty) {
        spans.add(TextSpan(text: trailing, style: style));
      }

      currentIndex = match.end;
    }

    if (currentIndex < segment.length) {
      spans.add(TextSpan(
        text: segment.substring(currentIndex),
        style: style,
      ));
    }
  }

  Widget _buildBulletPoint(String line) {
    String cleaned = line.trim();
    
    // Remove leading bullet characters
    if (cleaned.startsWith('•') || cleaned.startsWith('-') || cleaned.startsWith('*')) {
      cleaned = cleaned.substring(1).trim();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.poppins(
              fontSize: widget.fontSize,
              color: widget.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: RichText(
              text: _buildInlineFormattedSpan(cleaned, widget.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

enum _FormatType { bold, italic }

class _FormatMatch {
  final int start;
  final int end;
  final String text;
  final _FormatType type;

  _FormatMatch(this.start, this.end, this.text, this.type);
}
