import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  /// Fetches current weather for given coordinates using Open-Meteo API (No Key Required)
  static Future<Map<String, dynamic>?> fetchCurrentWeather(
    double lat,
    double lng,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current_weather=true',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        if (current == null) return null;

        final code = current['weathercode'] as int?;
        final temp = (current['temperature'] as num?)?.toDouble() ?? 0.0;

        final condition = _getConditionFromCode(code);

        return {
          'temperature': temp,
          'condition': condition,
          'description': 'Temp: $temp°C, $condition',
        };
      }
    } catch (e) {
      debugPrint('WeatherService Error: $e');
    }
    return null;
  }

  static String _getConditionFromCode(int? code) {
    if (code == null) return 'Unknown';
    // WMO Weather interpretation codes (WW)
    if (code == 0) return 'Clear sky';
    if (code == 1 || code == 2 || code == 3) {
      return 'Mainly clear / Partly cloudy';
    }
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 71 && code <= 75) return 'Snow fall';
    if (code >= 80 && code <= 82) return 'Rain showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Unknown';
  }
}
