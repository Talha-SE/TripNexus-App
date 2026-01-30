import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../services/open_meteo_service.dart';
import '../../services/weather_notification_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _meteoService = OpenMeteoService.getInstance();
  final _notificationService = WeatherNotificationService.getInstance();
  Timer? _debounce;
  Timer? _autoRefreshTimer;
  TabController? _tabController;
  
  List<CityLocation> _searchResults = [];
  List<String> _searchHistory = [];
  List<SavedWeatherCity> _savedCities = [];
  int _currentTabIndex = 0;
  CityLocation? _selectedCity;
  Map<String, dynamic>? _weatherData;
  bool _isSearching = false;
  bool _isLoadingWeather = false;

  // Alert Types based on referencecode.tsx
  Map<String, dynamic>? _getDailyAlert(int index) {
    if (_weatherData == null || _weatherData!['daily'] == null) return null;
    
    final daily = _weatherData!['daily'];
    final code = daily['weather_code'][index] as int;
    final maxTemp = daily['temperature_2m_max'][index] as double;
    final minTemp = daily['temperature_2m_min'][index] as double;
    final wind = daily['wind_speed_10m_max'][index] as double;
    final rainSum = daily['precipitation_sum'][index] as double;
    final uvMax = daily['uv_index_max'][index] as double;

    // Priority 1: Dangerous Weather
    if (code >= 95) {
      return {
        'type': 'storm',
        'label': 'Storm Warning',
        'icon': Icons.thunderstorm_rounded,
        'color': Colors.purple.shade300,
        'bgColor': Colors.purple.withOpacity(0.15),
      };
    }
    if (wind > 40) {
      return {
        'type': 'wind',
        'label': 'High Wind',
        'icon': Icons.air_rounded,
        'color': Colors.blueGrey.shade300,
        'bgColor': Colors.blueGrey.withOpacity(0.15),
      };
    }
    
    // Priority 2: Temperature Extremes
    if (maxTemp > 35) {
      return {
        'type': 'heat',
        'label': 'Extreme Heat',
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.orange.shade300,
        'bgColor': Colors.orange.withOpacity(0.15),
      };
    }
    if (minTemp < 0) {
      return {
        'type': 'cold',
        'label': 'Freeze Warning',
        'icon': Icons.ac_unit_rounded,
        'color': Colors.cyan.shade400,
        'bgColor': Colors.cyan.withOpacity(0.2),
      };
    }
    
    // Priority 3: Common Inconveniences
    if (rainSum > 15) {
      return {
        'type': 'rain',
        'label': 'Heavy Rain',
        'icon': Icons.umbrella_rounded,
        'color': Colors.blue.shade400,
        'bgColor': Colors.blue.withOpacity(0.2),
      };
    }
    if (code >= 71 && code <= 77) {
      return {
        'type': 'snow',
        'label': 'Snow Alert',
        'icon': Icons.snowing,
        'color': Colors.white,
        'bgColor': Colors.white.withOpacity(0.2),
      };
    }
    if (uvMax >= 8) {
      return {
        'type': 'uv',
        'label': 'High UV',
        'icon': Icons.wb_sunny_rounded,
        'color': Colors.yellow.shade400,
        'bgColor': Colors.yellow.withOpacity(0.2),
      };
    }

    return null;
  }

  Map<String, dynamic>? _getHourlyAlert(int index) {
    if (_weatherData == null || _weatherData!['hourly'] == null) return null;
    
    final hourly = _weatherData!['hourly'];
    final code = hourly['weather_code'][index] as int;
    final wind = hourly['wind_speed_10m'][index] as double;
    final uv = hourly['uv_index'][index] as double;
    final pop = hourly['precipitation_probability'][index] as int;

    if (code >= 95) return {'icon': Icons.bolt_rounded, 'color': Colors.purple.shade400};
    if (pop > 70 && code >= 51) return {'icon': Icons.umbrella_rounded, 'color': Colors.blue.shade400};
    if (uv > 8) return {'icon': Icons.wb_sunny_rounded, 'color': Colors.orange.shade400};
    if (wind > 30) return {'icon': Icons.air_rounded, 'color': Colors.blueGrey.shade400};
    
    return null;
  }

  String _getSmartAdvice() {
    if (_weatherData == null || _weatherData!['current'] == null) return "Enjoy your travels!";
    
    final current = _weatherData!['current'];
    final code = current['weather_code'] as int;
    final temp = current['temperature_2m'] as double;
    final wind = current['wind_speed_10m'] as double;
    final rainProb = (_weatherData!['hourly']?['precipitation_probability']?[0] as int?) ?? 0;

    if (code >= 95) return "Stay indoors! Unsafe for sightseeing right now.";
    if (code >= 71 && code <= 77) return "Snowy day! Perfect for cozy indoor visits.";
    if (rainProb > 70 || (code >= 51 && code <= 67)) return "Heavy rain. Museum or gallery visits recommended.";
    if (rainProb > 30) return "Light rain expected. Keep an umbrella handy while exploring.";
    if (temp > 35) return "Extreme heat! Avoid long outdoor tours today.";
    if (temp > 28) return "Warm day. Stay hydrated during your city walk.";
    if (temp < 5) return "Freezing! Dress in layers for outdoor attractions.";
    if (temp < 15) return "Chilly weather. A light jacket is recommended for tours.";
    if (wind > 30) return "Very windy. Be careful at high-altitude viewpoints.";
    if (code == 0) return "Clear skies! Excellent day for outdoor photography and landmarks.";
    if (code >= 1 && code <= 3) return "Partly cloudy. Great for exploring the city comfortably.";
    
    return "Great day to explore! Enjoy your trip.";
  }

  @override
  void initState() {
    super.initState();
    _initializeWeatherService();
    _loadSearchHistory();
    _loadSavedCities();
    _startAutoRefresh();
  }

  Future<void> _initializeWeatherService() async {
    await _notificationService.initialize();
  }

  Future<void> _loadSavedCities() async {
    _savedCities = _notificationService.savedCities;
    if (_savedCities.isNotEmpty) {
      _tabController = TabController(length: _savedCities.length, vsync: this);
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          setState(() {
            _currentTabIndex = _tabController!.index;
            _loadWeatherForSavedCity(_currentTabIndex);
          });
        }
      });
      _loadWeatherForSavedCity(0);
    }
    setState(() {});
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (_savedCities.isNotEmpty && _currentTabIndex < _savedCities.length) {
        _refreshCurrentCity();
      }
    });
  }

  Future<void> _refreshCurrentCity() async {
    if (_savedCities.isEmpty || _currentTabIndex >= _savedCities.length) return;
    
    setState(() => _isLoadingWeather = true);
    await _notificationService.refreshCity(_currentTabIndex);
    await _loadSavedCities();
    _loadWeatherForSavedCity(_currentTabIndex);
  }

  void _loadWeatherForSavedCity(int index) {
    if (index >= 0 && index < _savedCities.length) {
      final city = _savedCities[index];
      setState(() {
        _weatherData = city.lastWeatherData;
        _selectedCity = CityLocation(
          name: city.name.split(',').first,
          latitude: city.latitude,
          longitude: city.longitude,
        );
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _removeSavedCity(int index) async {
    await _notificationService.removeCity(index);
    await _loadSavedCities();
    if (_savedCities.isEmpty) {
      setState(() {
        _weatherData = null;
        _selectedCity = null;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _autoRefreshTimer?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('weather_search_history') ?? [];
    setState(() => _searchHistory = history.take(5).toList());
  }

  Future<void> _saveToSearchHistory(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(cityName);
    _searchHistory.insert(0, cityName);
    if (_searchHistory.length > 5) {
      _searchHistory = _searchHistory.take(5).toList();
    }
    await prefs.setStringList('weather_search_history', _searchHistory);
    setState(() {});
  }

  void _searchCities(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _meteoService.searchCities(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _selectCity(CityLocation city) async {
    setState(() {
      _selectedCity = city;
      _searchResults = [];
      _searchController.text = city.displayName;
      _isLoadingWeather = true;
      _weatherData = null;
    });

    
    // Add to saved cities for tabs
    await _notificationService.addCity(city);
    await _loadSavedCities();
    // Save to search history
    await _saveToSearchHistory(city.displayName);

    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    final result = await _meteoService.getWeatherForecast(
      latitude: city.latitude,
      longitude: city.longitude,
    );

    if (mounted) {
      setState(() {
        _isLoadingWeather = false;
        if (result['success']) {
          _weatherData = result['data'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to load weather')),
          );
        }
      });
    }
  }

  Future<void> _selectFromHistory(String cityName) async {
    _searchController.text = cityName;
    // Trigger search to find the city
    final results = await _meteoService.searchCities(cityName);
    if (results.isNotEmpty) {
      _selectCity(results.first);
    }
  }

  List<Color> _getBackgroundColors(int weatherCode, bool isDay) {
    if (!isDay) {
      return [
        const Color(0xFF0F172A), // Slate 900
        const Color(0xFF1E293B), // Slate 800
        const Color(0xFF334155), // Slate 700
      ];
    }
    
    switch (weatherCode) {
      case 0: // Clear
        return [
          const Color(0xFF38BDF8), // Sky 400
          const Color(0xFF0EA5E9), // Sky 500
          const Color(0xFFF0F9FF), // Sky 50
        ];
      case 1:
      case 2:
      case 3: // Partly Cloudy
        return [
          const Color(0xFF60A5FA), // Blue 400
          const Color(0xFF93C5FD), // Blue 300
          const Color(0xFFEFF6FF), // Blue 50
        ];
      case 45:
      case 48: // Fog
        return [
          const Color(0xFF94A3B8), // Slate 400
          const Color(0xFFCBD5E1), // Slate 300
          const Color(0xFFF8FAFC), // Slate 50
        ];
      case 51:
      case 53:
      case 55:
      case 80:
      case 81:
      case 82: // Rain
        return [
          const Color(0xFF475569), // Slate 600
          const Color(0xFF64748B), // Slate 500
          const Color(0xFF94A3B8), // Slate 400
        ];
      case 95:
      case 96:
      case 99: // Storm
        return [
          const Color(0xFF1E1B4B), // Indigo 950
          const Color(0xFF312E81), // Indigo 900
          const Color(0xFF4338CA), // Indigo 700
        ];
      default:
        return [
          const Color(0xFF38BDF8), // Sky 400
          const Color(0xFF0EA5E9), // Sky 500
          const Color(0xFFF0F9FF), // Sky 50
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weatherCode = _weatherData?['current']?['weather_code'] as int? ?? 0;
    final isDay = (_weatherData?['current']?['is_day'] as int? ?? 1) == 1;
    final bgColors = _getBackgroundColors(weatherCode, isDay);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Weather Forecast',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (_savedCities.isNotEmpty && _weatherData != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refreshCurrentCity,
              tooltip: 'Refresh Weather',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Dynamic Background
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgColors,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                if (_savedCities.isNotEmpty) _buildModernTabBar(),
                _buildSearchHeader(),
                Expanded(
                  child: _buildBodyContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        physics: const BouncingScrollPhysics(),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.15),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        dividerColor: Colors.transparent,
        tabs: _savedCities.asMap().entries.map((entry) {
          final isSelected = _tabController?.index == entry.key;
          return Tab(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected ? Colors.transparent : Colors.black.withOpacity(0.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.value.name.split(',').first,
                    style: GoogleFonts.poppins(
                      fontSize: 13, 
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeSavedCity(entry.key),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoadingWeather) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing atmospheric data...',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_weatherData != null) {
      return _buildWeatherContent();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Searches',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_searchHistory.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('weather_search_history');
                    setState(() => _searchHistory = []);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white70),
                  label: Text(
                    'Clear',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((city) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: InkWell(
                    onTap: () => _selectFromHistory(city),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        city,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _searchCities,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              cursorColor: isDark ? Colors.white : Colors.blue,
              decoration: InputDecoration(
                hintText: 'Search city...',
                hintStyle: GoogleFonts.poppins(
                  color: isDark ? Colors.white38 : Colors.blueGrey.shade300,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  size: 20,
                ),
                suffixIcon: _isSearching
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white70 : Colors.blue.shade600,
                          ),
                        ),
                      )
                    : (_searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35, // Dynamic height limit
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    final city = _searchResults[index];
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () => _selectCity(city),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Icon(
                          Icons.location_on_rounded, 
                          color: isDark ? Colors.white54 : Colors.blue.shade400, 
                          size: 18
                        ),
                        title: Text(
                          city.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          [city.admin1, city.country].where((e) => e != null).join(', '),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      child: _isSearching && _searchResults.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final city = _searchResults[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          onTap: () => _selectCity(city),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            city.name,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          subtitle: Text(
                            [city.admin1, city.country].where((e) => e != null).join(', '),
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.cloud_outlined,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Explore Global Weather',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Search for any city to get precise real-time\nweather insights and smart travel advice.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 48),
          if (_searchHistory.isNotEmpty) ...[
            Text(
              'RECENT SEARCHES',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _searchHistory.map((city) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectFromHistory(city),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Text(
                        city,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSunCycleCard(Map<String, dynamic> daily) {
    final sunriseStr = daily['sunrise']?[0] as String?;
    final sunsetStr = daily['sunset']?[0] as String?;
    
    if (sunriseStr == null || sunsetStr == null) return const SizedBox.shrink();

    final sunrise = DateTime.parse(sunriseStr);
    final sunset = DateTime.parse(sunsetStr);
    final now = DateTime.now();
    
    // Calculate progress (0.0 to 1.0)
    double progress = 0.0;
    if (now.isAfter(sunrise) && now.isBefore(sunset)) {
      final totalDuration = sunset.difference(sunrise).inMinutes;
      final elapsed = now.difference(sunrise).inMinutes;
      progress = (elapsed / totalDuration).clamp(0.0, 1.0);
    } else if (now.isAfter(sunset)) {
      progress = 1.0;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Sun Cycle'),
                  Icon(Icons.wb_sunny_outlined, color: Colors.yellow.shade200, size: 20),
                ],
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Path
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: SunPathPainter(progress: progress),
                    ),
                  ),
                  // Current Status Text
                  Column(
                    children: [
                      Text(
                        now.isBefore(sunrise) 
                          ? 'Sunrise in ${_formatDuration(sunrise.difference(now))}'
                          : now.isBefore(sunset)
                            ? 'Sunset in ${_formatDuration(sunset.difference(now))}'
                            : 'Sun has set',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSunTimeItem('Sunrise', sunrise, Icons.wb_sunny_rounded, Colors.orange.shade300),
                  _buildSunTimeItem('Sunset', sunset, Icons.nights_stay_rounded, Colors.purple.shade300),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSunTimeItem(String label, DateTime time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              DateFormat('HH:mm').format(time),
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  Widget _buildWeatherContent() {
    final current = _weatherData!['current'];
    final hourly = _weatherData!['hourly'];
    final daily = _weatherData!['daily'];

    final weatherCode = current['weather_code'] as int? ?? 0;
    final isDay = (current['is_day'] as int? ?? 1) == 1;

    final todayAlert = _getDailyAlert(0);
    final isSevere = todayAlert != null && (todayAlert['type'] == 'storm' || todayAlert['type'] == 'heat' || todayAlert['type'] == 'wind');

    return RefreshIndicator(
      onRefresh: _refreshCurrentCity,
      color: Colors.blue.shade600,
      backgroundColor: Colors.white,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSevere) _buildSevereAlertBanner(todayAlert!),
              if (isSevere) const SizedBox(height: 20),
              _buildCurrentWeatherCard(current, weatherCode, isDay),
              const SizedBox(height: 32),
              _buildSunCycleCard(daily),
              const SizedBox(height: 32),
              _buildSectionHeader('Weather Insights'),
              const SizedBox(height: 16),
              _buildWeatherDetailsGrid(current),
              const SizedBox(height: 40),
              _buildSectionHeader('Hourly Outlook'),
              const SizedBox(height: 16),
              _buildHourlyForecast(hourly),
              const SizedBox(height: 40),
              _buildSectionHeader('7-Day Forecast'),
              const SizedBox(height: 16),
              _buildDailyForecast(daily),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSevereAlertBanner(Map<String, dynamic> alert) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: alert['color'].withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: alert['color'].withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alert['color'],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(alert['icon'], color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEVERE WEATHER ALERT',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: alert['color'],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert['label'],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Precaution advised for your area.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCurrentWeatherCard(Map<String, dynamic> current, int weatherCode, bool isDay) {
    final temp = current['temperature_2m'];
    final feelsLike = current['apparent_temperature'];
    final icon = _meteoService.getWeatherIcon(weatherCode, isDay);
    final description = _meteoService.getWeatherDescription(weatherCode);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedCity?.name ?? 'Select City',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isDay ? 'DAY' : 'NIGHT',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 4,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          icon,
                          style: const TextStyle(fontSize: 64, height: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${temp?.round() ?? '--'}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 54,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 0.9,
                                  ),
                                ),
                                Text(
                                  '°',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            description,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Feels like ${feelsLike?.round() ?? '--'}°',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.yellow, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SMART TRAVEL ADVICE',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.yellow.shade200,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getSmartAdvice(),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.3,
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
        ),
      ),
    );
  }

  Widget _buildWeatherDetailsGrid(Map<String, dynamic> current) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildDetailCard(
          'Humidity',
          '${current['relative_humidity_2m']?.round() ?? '--'}%',
          Icons.water_drop_rounded,
          Colors.blue.shade300,
        ),
        _buildDetailCard(
          'Wind',
          '${current['wind_speed_10m']?.round() ?? '--'} km/h',
          Icons.air_rounded,
          Colors.cyan.shade300,
        ),
        _buildDetailCard(
          'Precip',
          '${current['precipitation']?.toStringAsFixed(1) ?? '0.0'} mm',
          Icons.opacity_rounded,
          Colors.indigo.shade300,
        ),
        _buildDetailCard(
          'UV Index',
          '${current['uv_index']?.toStringAsFixed(1) ?? '--'}',
          Icons.wb_sunny_rounded,
          Colors.orange.shade300,
        ),
      ],
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
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



  Widget _buildHourlyForecast(Map<String, dynamic> hourly) {
    final times = (hourly['time'] as List).cast<String>();
    final temps = (hourly['temperature_2m'] as List).cast<num>();
    final weatherCodes = (hourly['weather_code'] as List).cast<num>();

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 24,
        itemBuilder: (context, index) {
          final time = DateTime.parse(times[index]);
          final isNow = index == 0;
          final alert = _getHourlyAlert(index);
          
          return Stack(
            children: [
              Container(
                width: 75,
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isNow ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isNow ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isNow ? 'Now' : DateFormat('HH:mm').format(time),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _meteoService.getWeatherIcon(weatherCodes[index].toInt(), true),
                            style: const TextStyle(fontSize: 24),
                          ),
                          Text(
                            '${temps[index].round()}°',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (alert != null)
                Positioned(
                  top: 8,
                  right: 20,
                  child: Icon(
                    alert['icon'],
                    size: 14,
                    color: alert['color'],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDailyForecast(Map<String, dynamic> daily) {
    final times = (daily['time'] as List).cast<String>();
    final maxTemps = (daily['temperature_2m_max'] as List).cast<num>();
    final minTemps = (daily['temperature_2m_min'] as List).cast<num>();
    final weatherCodes = (daily['weather_code'] as List).cast<num>();

    return Column(
      children: List.generate(7, (index) {
        final date = DateTime.parse(times[index]);
        final isToday = index == 0;
        final alert = _getDailyAlert(index);
        final description = _meteoService.getWeatherDescription(weatherCodes[index].toInt());

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isToday ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isToday ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday ? 'Today' : DateFormat('EEEE').format(date),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d').format(date),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _meteoService.getWeatherIcon(weatherCodes[index].toInt(), true),
                                style: const TextStyle(fontSize: 24),
                              ),
                              if (alert != null) const SizedBox(width: 8),
                              if (alert != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: alert['bgColor'],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: alert['color'].withOpacity(0.3)),
                                  ),
                                  child: Icon(alert['icon'], size: 12, color: alert['color']),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white60,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${maxTemps[index].round()}°',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${minTemps[index].round()}°',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white38,
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
        );
      }),
    );
  }
}

class SunPathPainter extends CustomPainter {
  final double progress;

  SunPathPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      -size.height * 0.5,
      size.width,
      size.height,
    );

    // Draw background path
    canvas.drawPath(path, paint);

    // Draw active path (progress)
    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.orange.shade300, Colors.yellow.shade200],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractPath, activePaint);
      
      // Draw sun icon at the current position
      if (progress > 0 && progress < 1) {
        final pos = metric.getTangentForOffset(metric.length * progress)?.position;
        if (pos != null) {
          final sunPaint = Paint()
            ..color = Colors.yellow.shade400
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          
          canvas.drawCircle(pos, 10, sunPaint);
          canvas.drawCircle(pos, 6, Paint()..color = Colors.yellow.shade200);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SunPathPainter oldDelegate) => 
      oldDelegate.progress != progress;
}
