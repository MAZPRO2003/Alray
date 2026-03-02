import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permissions are denied.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      // Using open-meteo for free weather data without an API key
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherData = data['current_weather'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load weather data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching weather: $e';
          _isLoading = false;
        });
      }
    }
  }

  IconData _getWeatherIcon(int weatherCode) {
    // Open-Meteo WMO Weather interpretation codes
    if (weatherCode == 0) return Icons.wb_sunny; // Clear sky
    if (weatherCode >= 1 && weatherCode <= 3) {
      return Icons.cloud; // Partly cloudy
    }
    if (weatherCode >= 45 && weatherCode <= 48) return Icons.foggy; // Fog
    if (weatherCode >= 51 && weatherCode <= 67) {
      return Icons.water_drop; // Rain/Drizzle
    }
    if (weatherCode >= 71 && weatherCode <= 86) return Icons.ac_unit; // Snow
    if (weatherCode >= 95 && weatherCode <= 99) {
      return Icons.thunderstorm; // Thunderstorm
    }
    return Icons.wb_cloudy; // Default
  }

  String _getWeatherDescription(int weatherCode) {
    if (weatherCode == 0) return 'Clear sky';
    if (weatherCode >= 1 && weatherCode <= 3) return 'Partly cloudy';
    if (weatherCode >= 45 && weatherCode <= 48) return 'Fog';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Rain';
    if (weatherCode >= 71 && weatherCode <= 86) return 'Snow';
    if (weatherCode >= 95 && weatherCode <= 99) return 'Thunderstorm';
    return 'Cloudy';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Fetching local weather...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _fetchWeather();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_weatherData == null) return const SizedBox.shrink();

    final temp = _weatherData!['temperature'];
    final weatherCode = _weatherData!['weathercode'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getWeatherIcon(weatherCode),
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Weather',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getWeatherDescription(weatherCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${temp.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
