import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// نموذج بيانات الطقس
class WeatherData {
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final String city;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.city,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
      city: json['name'],
    );
  }

  /// الوصف بالعربي
  String get arabicDescription {
    final desc = description.toLowerCase();
    if (desc.contains('clear')) return 'صحو';
    if (desc.contains('cloud')) return 'غائم جزئياً';
    if (desc.contains('rain')) return 'ممطر';
    if (desc.contains('thunder')) return 'عاصف';
    if (desc.contains('snow')) return 'ثلجي';
    if (desc.contains('mist') || desc.contains('fog')) return 'ضبابي';
    if (desc.contains('dust') || desc.contains('sand')) return 'غبار';
    return description;
  }

  /// رمز أيقونة الطقس
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
}

/// خدمة الطقس باستخدام OpenWeatherMap API
class WeatherService {
  // ⚠️ مهم: احصل على API Key مجاني من https://openweathermap.org/api
  // بعد التسجيل، ضع المفتاح هنا:
  static const String _apiKey = 'YOUR_OPENWEATHER_API_KEY';  // 👈 غيّر هنا!
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// جلب بيانات الطقس بناءً على الإحداثيات
  static Future<WeatherData?> getWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('🌤️ جلب بيانات الطقس للموقع: $latitude, $longitude');

      final url = Uri.parse(
        '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&lang=ar',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherData.fromJson(data);
        debugPrint('✅ تم جلب بيانات الطقس: ${weather.temperature}°C - ${weather.arabicDescription}');
        return weather;
      } else {
        debugPrint('❌ فشل جلب بيانات الطقس: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات الطقس: $e');
      return null;
    }
  }

  /// جلب بيانات الطقس بناءً على اسم المدينة
  static Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      debugPrint('🌤️ جلب بيانات الطقس للمدينة: $cityName');

      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName,SA&appid=$_apiKey&units=metric&lang=ar',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = WeatherData.fromJson(data);
        debugPrint('✅ تم جلب بيانات الطقس: ${weather.temperature}°C - ${weather.arabicDescription}');
        return weather;
      } else {
        debugPrint('❌ فشل جلب بيانات الطقس: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات الطقس: $e');
      return null;
    }
  }

  /// الحصول على أيقونة الطقس
  static String getWeatherIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('clear') || desc.contains('صحو')) return '☀️';
    if (desc.contains('cloud') || desc.contains('غائم')) return '☁️';
    if (desc.contains('rain') || desc.contains('مطر')) return '🌧️';
    if (desc.contains('thunder') || desc.contains('رعد')) return '⛈️';
    if (desc.contains('snow') || desc.contains('ثلج')) return '❄️';
    if (desc.contains('mist') || desc.contains('fog') || desc.contains('ضباب')) return '🌫️';
    if (desc.contains('dust') || desc.contains('sand') || desc.contains('غبار')) return '🌪️';
    return '🌤️';
  }
}
