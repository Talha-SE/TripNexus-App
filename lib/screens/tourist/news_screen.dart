import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../models/news_model.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<NewsItem> _newsItems = [];
  bool _isLoading = false;
  String _errorMessage = '';
  NewsType? _activeFilter;

  @override
  void initState() {
    super.initState();
    _fetchNews('Travel Safety');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Improved query as in reference code
      final searchQuery = '$query tourism travel safety events';
      final response = await http.get(
        Uri.parse('https://news.google.com/rss/search?q=${Uri.encodeComponent(searchQuery)}&hl=en-US&gl=US&ceid=US:en'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        final List<NewsItem> news = [];
        for (var item in items) {
          final title = item.getElement('title')?.innerText ?? 'No Title';
          final link = item.getElement('link')?.innerText ?? '';
          final pubDate = item.getElement('pubDate')?.innerText ?? '';
          String description = item.getElement('description')?.innerText ?? '';
          final source = item.getElement('source')?.innerText ?? 'Google News';

          description = description.replaceAll(RegExp(r'<[^>]*>'), '');
          description = description
              .replaceAll('&quot;', '"')
              .replaceAll('&apos;', "'")
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>');

          // Heuristic to determine type as in reference code
          final lowerTitle = title.toLowerCase();
          NewsType type = NewsType.general;
          if (lowerTitle.contains('warning') ||
              lowerTitle.contains('alert') ||
              lowerTitle.contains('ban') ||
              lowerTitle.contains('danger') ||
              lowerTitle.contains('issue') ||
              lowerTitle.contains('storm') ||
              lowerTitle.contains('safety')) {
            type = NewsType.warning;
          } else if (lowerTitle.contains('festival') ||
              lowerTitle.contains('concert') ||
              lowerTitle.contains('exhibition') ||
              lowerTitle.contains('event') ||
              lowerTitle.contains('parade')) {
            type = NewsType.event;
          }

          news.add(NewsItem(
            title: title,
            link: link,
            pubDate: pubDate,
            description: description,
            source: source,
            type: type,
          ));
        }

        setState(() {
          _newsItems = news;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load news. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching news: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch news article')),
      );
    }
  }

  List<NewsItem> get _filteredNews {
    if (_activeFilter == null) return _newsItems;
    return _newsItems.where((item) => item.type == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: Navigator.canPop(context)
          ? AppBar(
              title: Text(
                'Events & News',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: true,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Color(AppConfig.primaryColor), const Color(0xFF1565C0)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Column(
        children: [
          if (!Navigator.canPop(context)) _buildHeader(),
          if (Navigator.canPop(context)) const SizedBox(height: 100),
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : _filteredNews.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _filteredNews.length,
                            itemBuilder: (context, index) {
                              return _buildNewsCard(_filteredNews[index], index);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search city (e.g., Paris, Tokyo)...',
            hintStyle: GoogleFonts.poppins(
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: Color(AppConfig.primaryColor),
                size: 18,
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                _fetchNews(_searchController.text);
                setState(() => _activeFilter = null);
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onSubmitted: (value) {
            _fetchNews(value);
            setState(() => _activeFilter = null);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(AppConfig.primaryColor)),
          const SizedBox(height: 16),
          Text(
            'Fetching live updates...',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Color(AppConfig.errorColor)),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchNews(_searchController.text.isEmpty ? 'Travel Safety' : _searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConfig.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No updates found for this category.',
            style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          if (_activeFilter != null)
            TextButton(
              onPressed: () => setState(() => _activeFilter = null),
              child: Text(
                'Clear Filters',
                style: GoogleFonts.poppins(color: Color(AppConfig.primaryColor), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [Color(AppConfig.primaryColor), const Color(0xFF1565C0)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Events & News',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Stay informed about local updates',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildFilterChip(null, 'All', null),
          _buildFilterChip(NewsType.event, 'Events', Icons.calendar_today_rounded),
          _buildFilterChip(NewsType.warning, 'Alerts', Icons.warning_amber_rounded),
          _buildFilterChip(NewsType.general, 'News', Icons.info_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildFilterChip(NewsType? type, String label, IconData? icon) {
    final isSelected = _activeFilter == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.white : const Color(0xFF1E293B))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (isDark ? Colors.white : const Color(0xFF1E293B))
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected 
                    ? (isDark ? Colors.black87 : Colors.white)
                    : Colors.grey,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? (isDark ? Colors.black87 : Colors.white)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsItem item, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (item.type) {
      case NewsType.warning:
        typeColor = Colors.red;
        typeIcon = Icons.shield_outlined;
        typeLabel = 'Alert';
        break;
      case NewsType.event:
        typeColor = Colors.purple;
        typeIcon = Icons.calendar_month_outlined;
        typeLabel = 'Event';
        break;
      case NewsType.general:
      default:
        typeColor = Colors.blue;
        typeIcon = Icons.info_outline_rounded;
        typeLabel = 'News';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative blob for warning/event
            if (item.type != NewsType.general)
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _launchUrl(item.link),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(typeIcon, size: 12, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  typeLabel.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: typeColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(item.pubDate),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.source,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: isDark ? Colors.white54 : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      // Very simple parsing for Google News RSS dates (e.g. "Thu, 29 Jan 2026 08:00:00 GMT")
      final parts = dateStr.split(' ');
      if (parts.length >= 4) {
        return '${parts[2]} ${parts[1]}, ${parts[3]}';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }
}
