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
      
      final budgetInfo = budget != null && budget.isNotEmpty
          ? '\n- Budget context: $budget'
          : '\n- Budget context: not specified';
      
      final messages = [
        {
          'role': 'system',
          'content': '''You are an elite AI travel planner that writes card-ready itinerary markdown.

Formatting rules:
1. Output only clean Markdown, no tables and no code blocks.
2. Use one H1 title, then short H2 sections, then H3 day headings.
3. Keep every day self-contained and easy to render in a collapsible card.
4. Use concise bullets under Morning, Afternoon, Evening, Budget, and Tip.
5. If a budget and currency are provided, use that currency consistently in costs and breakdowns.
6. Keep paragraphs short, with one to three sentences maximum.
7. Prefer vivid but practical language. Avoid filler and repetition.
8. Include exact place names, estimated times, and realistic costs.
9. Make the output visually clean so it reads well in a modern mobile UI.
10. End with a practical budget summary and travel advice.
11. Use clear place and dish names in each day so the app can attach matching images from the internet.'''
        },
        {
          'role': 'user',
          'content': '''Create a premium $duration-day trip plan for:

📍 Destination: $destination
⏱️ Duration: $duration days
🎯 Interests: $interests$budgetInfo

Use this exact structure and keep it tight enough for a modern card UI:

# 🌍 $destination Travel Plan

## 📋 Quick Snapshot
- Destination: $destination
- Duration: $duration days
- Travel style: [match the user's interests]
- Budget: [use the provided budget and currency if available, otherwise give a flexible estimate]

## 📅 Day-by-Day Plan

### Day 1 - [Theme Name]
**Morning**
- 🏛️ **[Location Name]** - [brief description].
- ☕ **[Cafe/Spot]** - [why it fits the day].

**Afternoon**
- 🎨 **[Activity]** - [brief details and estimated cost].
- 🌳 **[Park/Walk]** - [brief details].

**Evening**
- 🍽️ **Dinner at [Restaurant Name]** - [cuisine/atmosphere and estimated cost].
- 🌃 **[Evening Activity]** - [brief details].

**Budget**
- [Short daily budget estimate in the provided currency].

**Tip**
- ✨ [One practical hidden gem or local tip].

[Repeat the same day-card structure for all $duration days.]

## 🍽️ Culinary Highlights
- 🥘 **Must-Try Dishes**: [3 to 5 dishes with brief descriptions]
- 🍷 **Top Dining Spots**: [3 to 4 places]

## 🚇 Transportation
- 🚕 **Getting Around**: [best ways to move around]
- 💳 **Travel Pass/Costs**: [daily estimate or transport pass]

## 💰 Budget Breakdown
- 🏨 **Accommodation**: [range in the selected currency]
- 🎟️ **Daily Activities**: [range in the selected currency]
- 🍽️ **Daily Dining**: [range in the selected currency]
- 📈 **Total Estimated Cost**: [total in the selected currency]

## 🌱 Sustainable Travel
- [3 specific eco-friendly tips for this destination]

## 💡 Practical Advice
- 🛂 **Entry & Customs**: [crucial local info]
- 💵 **Money & Tipping**: [currency and etiquette]
- 📱 **Connectivity**: [SIM/eSIM advice]

Be specific with names of restaurants, museums, streets, and neighborhoods, but keep each bullet short enough for mobile cards.'''
        }
      ];

      final result = await _callMistralAPI(
        model: AppConfig.mistralTripPlanModel,
        messages: messages,
        temperature: 0.55,
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
