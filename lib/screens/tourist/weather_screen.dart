import 'dart:async';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Forecast'),
        elevation: 0,
        actions: [
          if (_savedCities.isNotEmpty && _weatherData != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshCurrentCity,
              tooltip: 'Refresh Weather',
            ),
        ],
        bottom: _savedCities.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _savedCities.asMap().entries.map((entry) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.value.name.split(',').first),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeSavedCity(entry.key),
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            : null,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          if (_searchHistory.isNotEmpty && _searchResults.isEmpty && _searchController.text.isEmpty)
            _buildSearchHistory(),
          if (_searchResults.isNotEmpty) _buildSearchResults(),
          if (_isLoadingWeather) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_isLoadingWeather && _weatherData != null)
            Expanded(child: _buildWeatherContent()),
          if (!_isLoadingWeather && _weatherData == null && _selectedCity == null)
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(AppConfig.textSecondaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((city) {
              return ActionChip(
                label: Text(
                  city,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                avatar: const Icon(Icons.history, size: 18),
                onPressed: () => _selectFromHistory(city),
                backgroundColor: Color(AppConfig.backgroundColor),
                side: BorderSide(
                  color: Color(AppConfig.primaryColor).withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConfig.primaryColor),
            Color(AppConfig.accentColor),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(AppConfig.primaryColor).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _searchCities,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Color(AppConfig.textPrimaryColor),
              ),
              decoration: InputDecoration(
                hintText: 'Search for a city...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: Color(AppConfig.primaryColor), size: 26),
                suffixIcon: _isSearching
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(AppConfig.primaryColor),
                          ),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _selectedCity = null;
                                _weatherData = null;
                              });
                            },
                          )
                        : null,
                filled: false,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Color(AppConfig.primaryColor),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final city = _searchResults[index];
          return ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(
              city.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [city.admin1, city.country].where((e) => e != null).join(', '),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: city.population != null
                ? Text(
                    '${(city.population! / 1000).round()}K',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  )
                : null,
            onTap: () => _selectCity(city),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_outlined, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Search for a city',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get detailed weather forecasts',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    final current = _weatherData!['current'];
    final hourly = _weatherData!['hourly'];
    final daily = _weatherData!['daily'];

    final weatherCode = current['weather_code'] as int? ?? 0;
    final isDay = (current['is_day'] as int? ?? 1) == 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentWeatherCard(current, weatherCode, isDay),
          const SizedBox(height: 20),
          _buildWeatherDetailsGrid(current),
          const SizedBox(height: 24),
          _buildSectionHeader('Hourly Forecast'),
          const SizedBox(height: 12),
          _buildHourlyForecast(hourly),
          const SizedBox(height: 24),
          _buildSectionHeader('7-Day Forecast'),
          const SizedBox(height: 12),
          _buildDailyForecast(daily),
          const SizedBox(height: 8),
        ],
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
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDay
              ? [
                  const Color(0xFF4A90E2),
                  const Color(0xFF50C9C3),
                ]
              : [
                  const Color(0xFF2C3E50),
                  const Color(0xFF4CA1AF),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(AppConfig.primaryColor).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCity?.name ?? 'Current Location',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${temp?.round() ?? '--'}',
                        style: GoogleFonts.poppins(
                          fontSize: 72,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '°C',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.thermostat_outlined,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Feels like ${feelsLike?.round() ?? '--'}°C',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 100),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailsGrid(Map<String, dynamic> current) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildDetailCard(
          'Humidity',
          '${current['relative_humidity_2m']?.round() ?? '--'}%',
          Icons.water_drop,
          Colors.blue,
        ),
        _buildDetailCard(
          'Wind Speed',
          '${current['wind_speed_10m']?.round() ?? '--'} km/h',
          Icons.air,
          Colors.cyan,
        ),
        _buildDetailCard(
          'Precipitation',
          '${current['precipitation']?.toStringAsFixed(1) ?? '0.0'} mm',
          Icons.opacity,
          Colors.indigo,
        ),
        _buildDetailCard(
          'Cloud Cover',
          '${current['cloud_cover']?.round() ?? '--'}%',
          Icons.cloud,
          Colors.blueGrey,
        ),
        _buildDetailCard(
          'UV Index',
          '${current['uv_index']?.toStringAsFixed(1) ?? '--'}',
          Icons.wb_sunny,
          Colors.orange,
        ),
        _buildDetailCard(
          'Wind Direction',
          _meteoService.getWindDirection(current['wind_direction_10m']?.round() ?? 0),
          Icons.explore,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConfig.textPrimaryColor),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(AppConfig.textSecondaryColor),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(AppConfig.textPrimaryColor),
      ),
    );
  }

  Widget _buildHourlyForecast(Map<String, dynamic> hourly) {
    final times = (hourly['time'] as List).cast<String>();
    final temps = (hourly['temperature_2m'] as List).cast<num>();
    final weatherCodes = (hourly['weather_code'] as List).cast<num>();
    final precipProb = (hourly['precipitation_probability'] as List).cast<num>();

    return SizedBox(
      height: 155,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: 24, // Next 24 hours
        itemBuilder: (context, index) {
          final time = DateTime.parse(times[index]);
          final isNow = index == 0;
          
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isNow
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(AppConfig.primaryColor),
                        Color(AppConfig.accentColor),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
                    ),
              boxShadow: [
                BoxShadow(
                  color: isNow
                      ? Color(AppConfig.primaryColor).withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isNow
                    ? Colors.transparent
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isNow ? 'Now' : DateFormat('HH:mm').format(time),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isNow ? Colors.white : Color(AppConfig.textPrimaryColor),
                    ),
                  ),
                  Text(
                    _meteoService.getWeatherIcon(weatherCodes[index].toInt(), true),
                    style: const TextStyle(fontSize: 32),
                  ),
                  Text(
                    '${temps[index].round()}°',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isNow ? Colors.white : Color(AppConfig.textPrimaryColor),
                    ),
                  ),
                  if (precipProb[index] > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isNow
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            size: 11,
                            color: isNow ? Colors.white : Colors.blue,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${precipProb[index].round()}%',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isNow ? Colors.white : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
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
    final precipProb = (daily['precipitation_probability_max'] as List).cast<num>();
    final uvIndex = (daily['uv_index_max'] as List).cast<num>();

    return Column(
      children: List.generate(7, (index) {
        final date = DateTime.parse(times[index]);
        final isToday = index == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isToday ? Color(AppConfig.primaryColor).withValues(alpha: 0.05) : Colors.white,
            border: Border.all(
              color: isToday
                  ? Color(AppConfig.primaryColor).withValues(alpha: 0.3)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday ? 'Today' : DateFormat('EEEE').format(date),
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(AppConfig.textPrimaryColor),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d').format(date),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(AppConfig.textSecondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _meteoService.getWeatherIcon(weatherCodes[index].toInt(), true),
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${maxTemps[index].round()}°',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(AppConfig.textPrimaryColor),
                          ),
                        ),
                        Text(
                          ' / ',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Color(AppConfig.textSecondaryColor),
                          ),
                        ),
                        Text(
                          '${minTemps[index].round()}°',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(AppConfig.textSecondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildDailyDetailChip(
                        Icons.water_drop_rounded,
                        '${precipProb[index].round()}%',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDailyDetailChip(
                        Icons.wb_sunny_rounded,
                        'UV ${uvIndex[index].toStringAsFixed(1)}',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDailyDetailChip(
                        Icons.thermostat_rounded,
                        '${((maxTemps[index] + minTemps[index]) / 2).round()}°',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDailyDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
