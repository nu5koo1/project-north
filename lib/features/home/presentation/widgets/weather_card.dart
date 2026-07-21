import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  static const Duration _locationTimeout = Duration(seconds: 10);
  static const Duration _networkTimeout = Duration(seconds: 12);

  _WeatherData? _weather;
  String? _errorMessage;

  bool _isLoading = true;
  bool _isRequestInProgress = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadWeather());
      }
    });
  }

  Future<void> _loadWeather() async {
    if (_isRequestInProgress) {
      return;
    }

    _isRequestInProgress = true;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final position = await _resolvePosition();
      final weather = await _fetchWeather(position);

      if (!mounted) {
        return;
      }

      setState(() {
        _weather = weather;
        _errorMessage = null;
        _isLoading = false;
      });
    } on _WeatherException catch (error) {
      debugPrint('Weather error: ${error.message}');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Unexpected weather error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Weather is unavailable right now.';
        _isLoading = false;
      });
    } finally {
      _isRequestInProgress = false;
    }
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
      _locationTimeout,
      onTimeout: () => false,
    );

    if (!serviceEnabled) {
      throw const _WeatherException(
        'Turn on location services to see local weather.',
      );
    }

    var permission = await Geolocator.checkPermission().timeout(
      _locationTimeout,
      onTimeout: () => LocationPermission.denied,
    );

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission().timeout(
        _locationTimeout,
        onTimeout: () => LocationPermission.denied,
      );
    }

    if (permission == LocationPermission.denied) {
      throw const _WeatherException(
        'Location permission is required for local weather.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const _WeatherException(
        'Allow location access in your device settings.',
      );
    }

    final lastKnownPosition = await Geolocator.getLastKnownPosition().timeout(
      const Duration(seconds: 4),
      onTimeout: () => null,
    );

    if (lastKnownPosition != null) {
      unawaited(_refreshWithCurrentPosition());
      return lastKnownPosition;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 100,
        ),
      ).timeout(_locationTimeout);
    } on TimeoutException {
      throw const _WeatherException(
        'Location could not be detected. Set a point in the emulator.',
      );
    } catch (error) {
      debugPrint('Current location error: $error');

      throw const _WeatherException(
        'Location could not be detected. Try again.',
      );
    }
  }

  Future<void> _refreshWithCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 100,
        ),
      ).timeout(_locationTimeout);

      final weather = await _fetchWeather(position);

      if (!mounted) {
        return;
      }

      setState(() {
        _weather = weather;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Background location refresh skipped: $error');
    }
  }

  Future<_WeatherData> _fetchWeather(Position position) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': position.latitude.toStringAsFixed(6),
      'longitude': position.longitude.toStringAsFixed(6),
      'current':
          'temperature_2m,apparent_temperature,weather_code,wind_speed_10m',
      'daily': 'sunset',
      'timezone': 'auto',
      'forecast_days': '1',
    });

    late http.Response response;

    try {
      response = await http.get(uri).timeout(_networkTimeout);
    } on TimeoutException {
      throw const _WeatherException('Weather request timed out. Try again.');
    } catch (error) {
      debugPrint('Weather network error: $error');

      throw const _WeatherException(
        'Check your internet connection and try again.',
      );
    }

    if (response.statusCode != 200) {
      throw _WeatherException(
        'Weather service returned error ${response.statusCode}.',
      );
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const _WeatherException('Weather data could not be read.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const _WeatherException('Weather data has an invalid format.');
    }

    final current = decoded['current'];
    final daily = decoded['daily'];

    if (current is! Map<String, dynamic>) {
      throw const _WeatherException('Current weather data is missing.');
    }

    final temperature = _readDouble(current['temperature_2m'], 'temperature');

    final feelsLike = _readDouble(
      current['apparent_temperature'],
      'apparent temperature',
    );

    final windSpeed = _readDouble(current['wind_speed_10m'], 'wind speed');

    final weatherCode = _readInt(current['weather_code'], 'weather code');

    String? sunset;

    if (daily is Map<String, dynamic>) {
      final sunsetValues = daily['sunset'];

      if (sunsetValues is List && sunsetValues.isNotEmpty) {
        sunset = _formatTime(sunsetValues.first?.toString());
      }
    }

    return _WeatherData(
      temperature: temperature,
      feelsLike: feelsLike,
      windSpeed: windSpeed,
      weatherCode: weatherCode,
      sunset: sunset,
    );
  }

  double _readDouble(Object? value, String fieldName) {
    if (value is num) {
      return value.toDouble();
    }

    final parsedValue = double.tryParse(value?.toString() ?? '');

    if (parsedValue == null) {
      throw _WeatherException('Weather $fieldName is missing.');
    }

    return parsedValue;
  }

  int _readInt(Object? value, String fieldName) {
    if (value is num) {
      return value.toInt();
    }

    final parsedValue = int.tryParse(value?.toString() ?? '');

    if (parsedValue == null) {
      throw _WeatherException('Weather $fieldName is missing.');
    }

    return parsedValue;
  }

  String? _formatTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final dateTime = DateTime.tryParse(value);

    if (dateTime == null) {
      return null;
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _WeatherLoadingCard();
    }

    final errorMessage = _errorMessage;

    if (errorMessage != null) {
      return _WeatherErrorCard(message: errorMessage, onRetry: _loadWeather);
    }

    final weather = _weather;

    if (weather == null) {
      return _WeatherErrorCard(
        message: 'Weather is unavailable right now.',
        onRetry: _loadWeather,
      );
    }

    return _WeatherContentCard(weather: weather, onRefresh: _loadWeather);
  }
}

class _WeatherContentCard extends StatelessWidget {
  const _WeatherContentCard({required this.weather, required this.onRefresh});

  final _WeatherData weather;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final presentation = _WeatherPresentation.fromCode(weather.weatherCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              presentation.icon,
              size: 32,
              color: presentation.iconColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weather near you',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  presentation.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 12,
                  runSpacing: 5,
                  children: [
                    _WeatherDetail(
                      icon: Icons.air_rounded,
                      label: '${weather.windSpeed.round()} km/h',
                    ),
                    _WeatherDetail(
                      icon: Icons.thermostat_rounded,
                      label: 'Feels ${weather.feelsLike.round()}°',
                    ),
                    if (weather.sunset != null)
                      _WeatherDetail(
                        icon: Icons.wb_twilight_rounded,
                        label: 'Sunset ${weather.sunset}',
                        isWarm: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${weather.temperature.round()}°',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: onRefresh,
                tooltip: 'Refresh weather',
                icon: const Icon(Icons.refresh_rounded, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  const _WeatherDetail({
    required this.icon,
    required this.label,
    this.isWarm = false,
  });

  final IconData icon;
  final String label;
  final bool isWarm;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isWarm ? AppColors.warning : AppColors.primary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WeatherLoadingCard extends StatelessWidget {
  const _WeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 112,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.3),
        ),
      ),
    );
  }
}

class _WeatherErrorCard extends StatelessWidget {
  const _WeatherErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_outlined,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            tooltip: 'Try again',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _WeatherData {
  const _WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.windSpeed,
    required this.weatherCode,
    required this.sunset,
  });

  final double temperature;
  final double feelsLike;
  final double windSpeed;
  final int weatherCode;
  final String? sunset;
}

class _WeatherPresentation {
  const _WeatherPresentation({
    required this.description,
    required this.icon,
    required this.iconColor,
  });

  final String description;
  final IconData icon;
  final Color iconColor;

  factory _WeatherPresentation.fromCode(int code) {
    if (code == 0) {
      return const _WeatherPresentation(
        description: 'Clear sky',
        icon: Icons.wb_sunny_rounded,
        iconColor: AppColors.warning,
      );
    }

    if (code == 1 || code == 2) {
      return const _WeatherPresentation(
        description: 'Partly cloudy',
        icon: Icons.wb_cloudy_rounded,
        iconColor: AppColors.warning,
      );
    }

    if (code == 3) {
      return const _WeatherPresentation(
        description: 'Cloudy',
        icon: Icons.cloud_rounded,
        iconColor: AppColors.textSecondary,
      );
    }

    if (code == 45 || code == 48) {
      return const _WeatherPresentation(
        description: 'Foggy',
        icon: Icons.foggy,
        iconColor: AppColors.textSecondary,
      );
    }

    if (code >= 51 && code <= 67) {
      return const _WeatherPresentation(
        description: 'Rain',
        icon: Icons.water_drop_rounded,
        iconColor: AppColors.primary,
      );
    }

    if (code >= 71 && code <= 77) {
      return const _WeatherPresentation(
        description: 'Snow',
        icon: Icons.ac_unit_rounded,
        iconColor: AppColors.primary,
      );
    }

    if (code >= 80 && code <= 82) {
      return const _WeatherPresentation(
        description: 'Rain showers',
        icon: Icons.water_drop_outlined,
        iconColor: AppColors.primary,
      );
    }

    if (code >= 85 && code <= 86) {
      return const _WeatherPresentation(
        description: 'Snow showers',
        icon: Icons.ac_unit_rounded,
        iconColor: AppColors.primary,
      );
    }

    if (code >= 95) {
      return const _WeatherPresentation(
        description: 'Thunderstorm',
        icon: Icons.thunderstorm_rounded,
        iconColor: AppColors.warning,
      );
    }

    return const _WeatherPresentation(
      description: 'Current conditions',
      icon: Icons.cloud_outlined,
      iconColor: AppColors.textSecondary,
    );
  }
}

class _WeatherException implements Exception {
  const _WeatherException(this.message);

  final String message;
}
