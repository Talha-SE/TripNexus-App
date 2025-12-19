import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormattedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;

  const FormattedText({
    Key? key,
    required this.text,
    this.fontSize = 14,
    this.textColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseText(text),
    );
  }

  List<Widget> _parseText(String text) {
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
    
    double headingSize = fontSize + (4 - level) * 2;
    if (headingSize < fontSize) headingSize = fontSize + 2;
    
    return Padding(
      padding: EdgeInsets.only(top: level == 1 ? 16 : 12, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: headingSize,
          fontWeight: level <= 2 ? FontWeight.bold : FontWeight.w600,
          color: textColor,
        ),
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
          fontSize: fontSize + 2,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
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
              fontSize: fontSize,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: _buildInlineFormatted(cleaned),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedLine(String line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _buildInlineFormatted(line),
    );
  }

  Widget _buildInlineFormatted(String text) {
    final spans = <TextSpan>[];
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
        spans.add(TextSpan(
          text: text.substring(currentIndex, formatMatch.start),
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            color: textColor,
          ),
        ));
      }

      // Add formatted text
      spans.add(TextSpan(
        text: formatMatch.text,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: formatMatch.type == _FormatType.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: formatMatch.type == _FormatType.italic ? FontStyle.italic : FontStyle.normal,
          color: textColor,
        ),
      ));

      currentIndex = formatMatch.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          color: textColor,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans.isEmpty ? [
          TextSpan(
            text: text,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: textColor,
            ),
          ),
        ] : spans,
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
