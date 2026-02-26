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
          'content': '''You are an elite AI luxury travel consultant. Your goal is to create high-end, visually structured, and deeply practical trip itineraries.
          
Rules for formatting:
1. Use professional and evocative language.
2. Use Markdown headings properly (# for title, ## for sections, ### for days).
3. Use relevant emojis at the start of every heading and important point.
4. Use **bold** for locations, times, and prices.
5. Use bullet points for activities and lists.
6. Group activities into Morning, Afternoon, and Evening.
7. Include estimated costs for every major activity and meal.
8. Add a "Pro Tip" or "Hidden Gem" for each day.
9. Keep the tone sophisticated yet welcoming.
10. Ensure the layout is clean with clear spacing between sections.'''
        },
        {
          'role': 'user',
          'content': '''Create a prestigious $duration-day trip plan for:

📍 Destination: $destination
⏱️ Duration: $duration days
🎯 Interests: $interests$budgetInfo

Please structure the response as follows:

# 🌍 Your Exclusive $duration-Day Journey to $destination

## 📋 Trip Overview
[A sophisticated 2-3 sentence introduction to the destination and the vibe of this trip.]

## 📅 The Itinerary

### 🌅 Day 1: [Elegant Theme Name]
**Morning (9:00 AM - 12:30 PM)**
• 🏛️ **[Location Name]** - [Brief description]. (Time: **2.5 hours**, Cost: **\$XX**)
• ☕ **[Cafe/Spot]** - [Why visit].

**Afternoon (1:30 PM - 5:30 PM)**
• 🎨 **[Activity]** - [Details]. (Cost: **\$XX**)
• 🌳 **[Park/Walk]** - [Details].

**Evening (7:00 PM+)**
• 🍽️ **Dinner at [Restaurant Name]** - [Cuisine/Atmosphere]. (Est. Cost: **\$XX**)
• 🌃 **[Evening Activity]** - [Details].

✨ **Hidden Gem:** [A unique, less-known spot or experience for today].

[Continue this exact structure for all $duration days]

## 🍽️ Culinary Highlights
• 🥘 **Must-Try Dishes**: [List with brief descriptions]
• 🍷 **Top Dining Spots**: [List of 3-4 varied restaurants]

## 🚇 Seamless Transportation
• 🚕 **Getting Around**: [Best ways to navigate]
• 💳 **Travel Pass/Costs**: [Specific card names or daily estimates]

## 💰 Investment Breakdown (USD)
• 🏨 **Accommodation**: **\$XX - \$XX** per night
• 🎟️ **Daily Activities**: **\$XX**
• 🍽️ **Daily Dining**: **\$XX**
• 📈 **Total Estimated Investment**: **\$XXXX**

## 🌱 Sustainable Travel
• [3 specific eco-friendly tips for this destination]

## 💡 Expert Travel Advice
• 🛂 **Entry & Customs**: [Crucial local info]
• 💵 **Money & Tipping**: [Local currency and etiquette]
• 📱 **Connectivity**: [SIM/eSIM advice]

Be extremely specific with names of restaurants, museums, and streets!'''
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
