// lib/services/gemini_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/weather_model.dart';

class GeminiService {
  late final GenerativeModel _model;
  
  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String> generateWeatherReport(Weather weather) async {
    try {
      // Craft a prompt with weather information
      final prompt = '''
Generate a concise, helpful weather report for ${weather.cityName} based on the following data:
- Current temperature: ${weather.temperature}°C
- Feels like: ${weather.feelsLike}°C
- Weather conditions: ${weather.description}
- Humidity: ${weather.humidity}%
- Wind speed: ${weather.windSpeed} m/s

The report should include:
1. A brief summary of current conditions
2. How it feels outside (hot, cold, pleasant, etc.)
3. A practical advice for the day based on the weather (what to wear, activities, etc.)
4. Keep it under 100 words
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'Unable to generate weather report';
    } catch (e) {
      return 'Error generating weather report: $e';
    }
  }
}