import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class MistralService {
  static MistralService? _instance;

  MistralService._();

  static MistralService getInstance() {
    _instance ??= MistralService._();
    return _instance!;
  }

  // Helper method to make API calls
  Future<Map<String, dynamic>> _callMistralAPI({
    required String model,
    required List<Map<String, dynamic>> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.mistralBaseUrl}/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.mistralApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      return {
        'statusCode': response.statusCode,
        'body': response.body,
      };
    } catch (e) {
      print('❌ API Call Error: $e');
      rethrow;
    }
  }

  /// Analyze landmark image using Mistral Medium vision model
  Future<Map<String, dynamic>> analyzeLandmarkImage(String base64Image) async {
    try {
      print('🔍 Analyzing landmark with Mistral Medium vision model...');
      
      final messages = [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': '''Analyze this landmark or location image and provide detailed information.

Format your response as follows:

🏛️ **Landmark Name**: [Name]

📍 **Location**: [City, Country]

📖 **About**: [Brief description and historical significance]

🌟 **Highlights**:
• [Feature 1]
• [Feature 2]
• [Feature 3]

⏰ **Best Time to Visit**: [Season/time]

💡 **Interesting Facts**:
• [Fact 1]
• [Fact 2]

🎫 **Tips for Visitors**: [Practical advice]'''
            },
            {
              'type': 'image_url',
              'image_url': 'data:image/jpeg;base64,$base64Image'
            }
          ]
        }
      ];

      final result = await _callMistralAPI(
        model: AppConfig.mistralLandmarkModel,
        messages: messages,
        temperature: 0.5,
        maxTokens: 2048,
      );

      print('📡 Response status: ${result['statusCode']}');
      
      if (result['statusCode'] == 200) {
        final data = jsonDecode(result['body']);
        print('✅ Landmark analysis successful');
        
        final analysis = data['choices'][0]['message']['content'];
        
        return {
          'success': true,
          'analysis': analysis ?? 'Unable to analyze the image. Please try again.',
        };
      } else if (result['statusCode'] == 429) {
        print('❌ Rate Limit Error (429)');
        return {
          'success': false,
          'message': 'API Rate Limit Reached. Please wait a moment before trying again or check your Mistral AI quota.',
        };
      } else {
        print('❌ API Error: ${result['statusCode']} - ${result['body']}');
        return {
          'success': false,
          'message': 'Failed to analyze image. Status: ${result['statusCode']}',
        };
      }
    } catch (e) {
      print('❌ Mistral Image Analysis Error: $e');
      return {
        'success': false,
        'message': 'An error occurred during image analysis: $e',
      };
    }
  }

  /// Generate detailed trip plan using Mistral Small model
  Future<Map<String, dynamic>> generateTripPlan({
    required String destination,
    required int duration,
    required String interests,
    String? budget,
  }) async {
    try {
      print('🗺️ Generating trip plan with Mistral Small...');
      
      final budgetInfo = budget != null && budget.isNotEmpty ? '\nBudget: $budget' : '';
      
      final messages = [
        {
          'role': 'system',
          'content': 'You are an expert AI trip planner. Create detailed, personalized day-by-day itineraries with specific places, times, and costs.'
        },
        {
          'role': 'user',
          'content': '''Create a detailed $duration-day trip plan:

📍 Destination: $destination
⏱️ Duration: $duration days
🎯 Interests: $interests$budgetInfo

Format:

# 🌍 Your $duration-Day Trip to $destination

## 📋 Overview
[Brief intro]

## 📅 Day-by-Day Itinerary

### Day 1: [Theme]
**Morning (9 AM - 12 PM)**
• Activity 1 (Location, time, cost)
• Activity 2

**Afternoon (1 PM - 5 PM)**
• Activity 1
• Activity 2

**Evening (6 PM+)**
• Dinner recommendations
• Evening activities

[Continue for all $duration days]

## 🍽️ Food Recommendations
• Must-try dishes
• Best restaurants

## 🚇 Transportation
• Getting around
• Costs

## 💰 Budget Estimate
• Daily breakdown
• Total estimate

## 🌱 Eco-Friendly Tips
• Sustainable options

## 💡 Travel Tips
• Local customs
• Money-saving tips

Be specific with locations, times, and realistic costs!'''
        }
      ];

      final result = await _callMistralAPI(
        model: AppConfig.mistralTripPlanModel,
        messages: messages,
        temperature: 0.7,
        maxTokens: 4096,
      );

      print('📡 Response status: ${result['statusCode']}');
      
      if (result['statusCode'] == 200) {
        final data = jsonDecode(result['body']);
        print('✅ Trip plan generated successfully');
        
        final tripPlan = data['choices'][0]['message']['content'];
        
        return {
          'success': true,
          'plan': tripPlan ?? 'Unable to generate trip plan. Please try again.',
        };
      } else if (result['statusCode'] == 429) {
        print('❌ Rate Limit Error (429)');
        return {
          'success': false,
          'message': 'API Rate Limit Reached. Please wait a moment before trying again or check your Mistral AI quota.',
        };
      } else {
        print('❌ API Error: ${result['statusCode']} - ${result['body']}');
        return {
          'success': false,
          'message': 'Failed to generate trip plan. Status: ${result['statusCode']}',
        };
      }
    } catch (e) {
      print('❌ Mistral Trip Planning Error: $e');
      return {
        'success': false,
        'message': 'An error occurred while generating trip plan: $e',
      };
    }
  }

  /// Get quick travel recommendations
  Future<Map<String, dynamic>> getTripRecommendations({
    required String destination,
    required String interests,
    required int duration,
    String? budget,
  }) async {
    try {
      print('💡 Getting travel recommendations...');
      
      final budgetInfo = budget != null && budget.isNotEmpty ? '\n- Budget: $budget' : '';
      
      final messages = [
        {
          'role': 'system',
          'content': 'You are a travel expert providing helpful recommendations for travelers.'
        },
        {
          'role': 'user',
          'content': '''Provide travel recommendations for:
- Destination: $destination
- Interests: $interests
- Duration: $duration days$budgetInfo

Include:
1. Top attractions
2. Recommended activities
3. Local cuisine
4. Cultural experiences
5. Transportation tips
6. Eco-friendly options'''
        }
      ];
      
      final result = await _callMistralAPI(
        model: AppConfig.mistralTripPlanModel,
        messages: messages,
        temperature: 0.7,
        maxTokens: 1500,
      );
      
      if (result['statusCode'] == 200) {
        final data = jsonDecode(result['body']);
        final recommendations = data['choices'][0]['message']['content'];
        
        return {
          'success': true,
          'message': recommendations,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get recommendations',
        };
      }
    } catch (e) {
      print('❌ Error: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  /// Get eco-friendly travel recommendations
  Future<Map<String, dynamic>> getEcoFriendlyRecommendations(String destination) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': 'You are an eco-tourism specialist helping travelers make environmentally conscious choices.'
        },
        {
          'role': 'user',
          'content': '''Provide eco-friendly travel recommendations for $destination:
1. Sustainable accommodations
2. Green transportation options
3. Eco-tourism activities
4. Local conservation efforts to support
5. Tips for reducing environmental impact'''
        }
      ];
      
      final result = await _callMistralAPI(
        model: AppConfig.mistralTripPlanModel,
        messages: messages,
        temperature: 0.7,
        maxTokens: 1500,
      );
      
      if (result['statusCode'] == 200) {
        final data = jsonDecode(result['body']);
        final recommendations = data['choices'][0]['message']['content'];
        
        return {
          'success': true,
          'message': recommendations,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get eco recommendations',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get eco recommendations: $e',
      };
    }
  }
}
