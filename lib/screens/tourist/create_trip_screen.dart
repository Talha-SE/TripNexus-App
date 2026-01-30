import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../models/trip_model.dart';
import '../../services/auth_service.dart';
import '../../services/mongodb_service.dart';
import '../../services/mistral_service.dart';
import '../../services/weather_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isEcoFriendly = false;
  bool _isLoading = false;
  final List<String> _activities = [];
  final _activityController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addActivity() {
    if (_activityController.text.isNotEmpty) {
      setState(() {
        _activities.add(_activityController.text);
        _activityController.clear();
      });
    }
  }

  Future<void> _getAIRecommendations() async {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mistral = MistralService.getInstance();
      final duration = _startDate != null && _endDate != null
          ? _endDate!.difference(_startDate!).inDays
          : 5;
      
      final result = await mistral.getTripRecommendations(
        destination: _destinationController.text,
        interests: _activities.join(', '),
        duration: duration,
        budget: _budgetController.text.isEmpty ? null : _budgetController.text,
      );

      if (mounted && result['success']) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('AI Recommendations', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Text(result['message'], style: GoogleFonts.poppins()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting recommendations: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkWeather() async {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final weather = WeatherService.getInstance();
      final result = await weather.getCurrentWeather(_destinationController.text);

      if (mounted && result['success']) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Weather at ${result['city']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${result['temperature']}°C', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold)),
                Text(result['description'], style: GoogleFonts.poppins()),
                const SizedBox(height: 16),
                Text('Humidity: ${result['humidity']}%', style: GoogleFonts.poppins()),
                Text('Wind: ${result['windSpeed']} m/s', style: GoogleFonts.poppins()),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting weather: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = await AuthService.getInstance();
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final trip = TripModel(
        userId: user.id!,
        title: _titleController.text,
        destination: _destinationController.text,
        description: _descriptionController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        budget: double.tryParse(_budgetController.text),
        activities: _activities,
        isEcoFriendly: _isEcoFriendly,
      );

      final mongoService = await MongoDBService.getInstance();
      final tripsCollection = mongoService.getTripsCollection();
      
      await tripsCollection.insertOne(trip.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip created successfully!'),
            backgroundColor: Color(AppConfig.accentColor),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving trip: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Trip Title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Please enter a destination' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startDate == null 
                          ? 'Start Date'
                          : DateFormat('MMM dd, yyyy').format(_startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _endDate == null
                          ? 'End Date'
                          : DateFormat('MMM dd, yyyy').format(_endDate!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget (Optional)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _activityController,
                    decoration: const InputDecoration(
                      labelText: 'Add Activity',
                      prefixIcon: Icon(Icons.local_activity),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addActivity,
                  icon: const Icon(Icons.add_circle),
                  color: Color(AppConfig.primaryColor),
                ),
              ],
            ),
            if (_activities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _activities.map((activity) {
                  return Chip(
                    label: Text(activity),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _activities.remove(activity));
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Eco-Friendly Trip', style: GoogleFonts.poppins()),
              subtitle: Text('Support sustainable tourism', style: GoogleFonts.poppins(fontSize: 12)),
              value: _isEcoFriendly,
              onChanged: (value) => setState(() => _isEcoFriendly = value),
              activeTrackColor: Color(AppConfig.accentColor),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _getAIRecommendations,
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('AI Tips'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _checkWeather,
                    icon: const Icon(Icons.wb_sunny),
                    label: const Text('Weather'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConfig.primaryColor),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Create Trip'),
            ),
          ],
        ),
      ),
    );
  }
}
