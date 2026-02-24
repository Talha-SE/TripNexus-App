# Mistral AI Integration Guide

## Overview
The app now uses **Mistral AI** with the Conversations API for advanced AI features:
- **Landmark Scanning**: Mistral Medium (vision-capable)
- **Trip Planning**: Mistral Large (advanced reasoning)

## API Configuration

### API Key
```
m4zp8gXR8wPsxhNmOmjbW07kAEYAaYhR
```

### Models Used
- **mistral-medium-latest**: For image analysis (vision-capable)
- **mistral-small-latest**: For detailed trip planning and recommendations

### Endpoints
- Base URL: `https://api.mistral.ai/v1/beta/conversations`
- Start Conversation: `/start`

## Features Implemented

### 1. 🏛️ Landmark Scanner (Mistral Medium)

**Purpose**: Analyze photos of landmarks and provide detailed information

**How it works**:
1. User takes/selects a photo
2. Image converted to base64
3. Sent to Mistral Medium with vision capability
4. AI identifies the landmark and provides:
   - Name and location
   - Historical significance
   - Highlights and features
   - Best time to visit
   - Interesting facts
   - Visitor information

**Screen**: [lib/screens/tourist/landmark_scanner_screen.dart](lib/screens/tourist/landmark_scanner_screen.dart)

**Usage**:
```dart
final mistral = MistralService.getInstance();
final result = await mistral.analyzeLandmarkImage(base64Image);

if (result['success']) {
  String analysis = result['analysis'];
  // Display the analysis
}
```

### 2. 🗺️ AI Trip Planner (Mistral Large)

**Purpose**: Generate detailed day-by-day trip itineraries

**How it works**:
1. User enters:
   - Destination
   - Duration (days)
   - Interests
   - Budget (optional)
2. Sent to Mistral Large with web search enabled
3. AI creates a comprehensive plan including:
   - Day-by-day itinerary
   - Morning/afternoon/evening activities
   - Time estimates and costs
   - Culinary highlights
   - Transportation tips
   - Budget breakdown
   - Eco-friendly options
   - Travel tips

**Screen**: [lib/screens/tourist/ai_trip_planner_screen.dart](lib/screens/tourist/ai_trip_planner_screen.dart)

**Usage**:
```dart
final mistral = MistralService.getInstance();
final result = await mistral.generateTripPlan(
  destination: 'Paris, France',
  duration: 7,
  interests: 'History, Art, Food',
  budget: '\$2000',
);

if (result['success']) {
  String plan = result['plan'];
  // Display the plan
}
```

### 3. 💡 Quick Recommendations (Mistral Medium)

**Purpose**: Get quick travel recommendations

**Usage**:
```dart
final result = await mistral.getTripRecommendations(
  destination: 'Tokyo',
  interests: 'Culture, Food',
  duration: 5,
  budget: 'Mid-range',
);
```

### 4. 🌱 Eco-Friendly Recommendations (Mistral Medium)

**Purpose**: Get sustainable travel options

**Usage**:
```dart
final result = await mistral.getEcoFriendlyRecommendations('Bali');
```

## Technical Implementation

### Conversation API Structure

```json
{
  "model": "mistral-medium-latest",
  "instructions": "System instructions for the AI",
  "inputs": [
    {
      "role": "user",
      "content": "User message or array with text + image"
    }
  ],
  "temperature": 0.7,
  "maxTokens": 4096,
  "topP": 1,
  "tools": [
    { "type": "web_search" }  // Optional: enables web search
  ]
}
```

### Image Analysis Request

```json
{
  "model": "mistral-medium-latest",
  "inputs": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Analyze this landmark..."
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,..."
          }
        }
      ]
    }
  ]
}
```

### Response Format

```json
{
  "messages": [
    {
      "role": "assistant",
      "content": "AI response text..."
    }
  ]
}
```

## Service Architecture

### MistralService (Singleton)

**File**: [lib/services/mistral_service.dart](lib/services/mistral_service.dart)

**Methods**:
- `analyzeLandmarkImage(String base64Image)` → Landmark analysis
- `generateTripPlan(...)` → Detailed trip planning
- `getTripRecommendations(...)` → Quick recommendations
- `getEcoFriendlyRecommendations(String destination)` → Eco tips

**Configuration**: [lib/config/app_config.dart](lib/config/app_config.dart)
- `mistralApiKey`: Your API key
- `mistralBaseUrl`: Conversations API endpoint
- `mistralLandmarkModel`: mistral-medium-latest
- `mistralTripPlanModel`: mistral-large-latest

## UI Components

### 1. Landmark Scanner Screen

**Features**:
- Camera and gallery image selection
- Real-time image analysis
- Formatted results display
- Loading states

**Access**: Home → Scan button OR Explore tab

### 2. AI Trip Planner Screen

**Features**:
- Form-based input (destination, duration, interests, budget)
- Beautiful loading animation
- Formatted itinerary display
- Save functionality (placeholder)
- Create new plan option

**Access**: Home → AI Planner button

### 3. Quick Actions (Dashboard)

Updated quick actions:
- 🤖 **AI Planner** → AI Trip Planner Screen
- 📷 **Scan** → Landmark Scanner
- ☀️ **Weather** → Weather Screen
- 👥 **Advisors** → Advisors Search

## Advanced Features

### Web Search Integration

Trip planner uses web search for up-to-date information:
```dart
'tools': [
  {'type': 'web_search'}
]
```

This allows the AI to fetch current:
- Opening hours
- Ticket prices
- Special events
- Recent reviews
- Travel advisories

### Temperature & Token Settings

**Landmark Analysis**:
- Temperature: 0.5 (more focused)
- Max Tokens: 2048
- TopP: 1

**Trip Planning**:
- Temperature: 0.7 (more creative)
- Max Tokens: 4096
- TopP: 1
- Web Search: Enabled

**Quick Recommendations**:
- Temperature: 0.7
- Max Tokens: 1500
- TopP: 1

## Error Handling

All methods include:
- Try-catch blocks
- HTTP status code validation
- User-friendly error messages
- Console logging for debugging

Example:
```dart
try {
  final result = await mistral.analyzeLandmarkImage(image);
  if (result['success']) {
    // Handle success
  } else {
    // Show error message
  }
} catch (e) {
  // Handle exception
}
```

## Testing

### Test Landmark Scanner
1. Open app → Home → Scan button
2. Take photo or select from gallery
3. Wait for analysis (5-15 seconds)
4. View formatted landmark information

### Test AI Trip Planner
1. Open app → Home → AI Planner button
2. Fill in form:
   - Destination: "Paris, France"
   - Duration: "7"
   - Interests: "Art, Food, History"
   - Budget: "\$3000" (optional)
3. Tap "Generate Trip Plan"
4. Wait for generation (10-30 seconds)
5. View detailed day-by-day itinerary

## Performance Considerations

### Response Times
- Landmark Analysis: 5-15 seconds
- Trip Planning: 10-30 seconds (web search enabled)
- Quick Recommendations: 5-10 seconds

### Optimization
- Images compressed before upload (max 1800x1800, 85% quality)
- Base64 encoding for image transfer
- Async/await for non-blocking UI
- Loading indicators for user feedback

## Limitations & Notes

1. **API Rate Limits**: Mistral API has rate limits; handle gracefully
2. **Image Size**: Large images may timeout; compress before sending
3. **Internet Required**: All features require active internet connection
4. **Response Variability**: AI responses may vary slightly each time

## Future Enhancements

- [ ] Save trip plans to MongoDB
- [ ] Share trip plans via link/PDF
- [ ] Bookmark favorite landmarks
- [ ] Multi-language support
- [ ] Offline mode with cached results
- [ ] Voice input for trip preferences
- [ ] Integration with booking platforms
- [ ] AR landmark overlay
- [ ] Social sharing of trips
- [ ] Collaborative trip planning

## Troubleshooting

### Issue: "Failed to analyze image"
**Solutions**:
- Check internet connection
- Verify image is not corrupted
- Try smaller image
- Check API key is valid

### Issue: "Failed to generate trip plan"
**Solutions**:
- Verify all required fields are filled
- Check duration is 1-30 days
- Ensure internet connection is stable
- Wait and retry (may be rate limit)

### Issue: Slow responses
**Solutions**:
- Normal for complex queries
- Trip planning with web search takes longer
- Reduce max tokens for faster responses
- Optimize image size for landmark scanning

## Code Examples

### Complete Landmark Analysis
```dart
// In your screen
Future<void> _scanLandmark(File imageFile) async {
  setState(() => _isAnalyzing = true);
  
  try {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final mistral = MistralService.getInstance();
    final result = await mistral.analyzeLandmarkImage(base64Image);
    
    if (result['success']) {
      setState(() {
        _analysis = result['analysis'];
        _isAnalyzing = false;
      });
    } else {
      // Show error
      _showError(result['message']);
    }
  } catch (e) {
    _showError('Error: $e');
  }
}
```

### Complete Trip Planning
```dart
Future<void> _createTripPlan() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() => _isGenerating = true);
  
  try {
    final mistral = MistralService.getInstance();
    final result = await mistral.generateTripPlan(
      destination: _destinationController.text,
      duration: int.parse(_durationController.text),
      interests: _interestsController.text,
      budget: _budgetController.text.isEmpty 
        ? null 
        : _budgetController.text,
    );
    
    if (result['success']) {
      setState(() {
        _tripPlan = result['plan'];
        _isGenerating = false;
      });
    } else {
      _showError(result['message']);
    }
  } catch (e) {
    _showError('Error: $e');
  }
}
```

## Resources

- **Mistral AI Documentation**: https://docs.mistral.ai/
- **Conversations API**: https://docs.mistral.ai/api#tag/conversations
- **Models**: https://docs.mistral.ai/getting-started/models/

---

**Integration Complete!** 🎉

All Mistral AI features are now fully implemented and ready to use.
