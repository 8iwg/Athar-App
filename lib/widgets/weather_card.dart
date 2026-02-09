import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/weather_service.dart';

/// ويدجت لعرض بيانات الطقس
class WeatherCard extends StatelessWidget {
  final WeatherData weather;
  final bool compact;

  const WeatherCard({
    super.key,
    required this.weather,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView();
    }
    return _buildFullView(context);
  }

  /// عرض مختصر
  Widget _buildCompactView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.earth.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            WeatherService.getWeatherIcon(weather.arabicDescription),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${weather.temperature.round()}°C',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rubik',
                ),
              ),
              Text(
                weather.arabicDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Rubik',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// عرض كامل
  Widget _buildFullView(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.earth.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // العنوان
          Row(
            children: [
              Icon(
                Icons.wb_sunny_outlined,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'حالة الطقس',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Rubik',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // درجة الحرارة والوصف
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                WeatherService.getWeatherIcon(weather.arabicDescription),
                style: const TextStyle(fontSize: 60),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.round()}°C',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Rubik',
                    ),
                  ),
                  Text(
                    weather.arabicDescription,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // التفاصيل
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  icon: Icons.water_drop_outlined,
                  label: 'الرطوبة',
                  value: '${weather.humidity}%',
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildDetailItem(
                  icon: Icons.air_outlined,
                  label: 'الرياح',
                  value: '${weather.windSpeed.round()} كم/س',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'Rubik',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Rubik',
          ),
        ),
      ],
    );
  }
}

/// ويدجت لجلب وعرض الطقس
class WeatherWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool compact;

  const WeatherWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.compact = false,
  });

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherData? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weather = await WeatherService.getWeatherByCoordinates(
        widget.latitude,
        widget.longitude,
      );

      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
          if (weather == null) {
            _error = 'تعذر جلب بيانات الطقس';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'حدث خطأ في جلب بيانات الطقس';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _weather == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'الطقس غير متوفر',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ),
      );
    }

    return WeatherCard(
      weather: _weather!,
      compact: widget.compact,
    );
  }
}
