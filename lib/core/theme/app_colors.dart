import 'package:flutter/material.dart';

/// نظام الألوان الأنيق لتطبيق أثر
/// تصميم راقي بألوان التراب والبيج والأبيض
class AppColors {
  AppColors._();

  // الألوان الأساسية - لون التراب الأنيق
  static const Color primary = Color(0xFFC4A27C); // بيج ذهبي
  static const Color primaryDark = Color(0xFFA58968); // تراب داكن
  static const Color primaryLight = Color(0xFFD4BC9E); // بيج فاتح
  
  // الألوان الثانوية - الأبيض والبيج
  static const Color background = Color(0xFFFAF7F2); // أبيض مع لمسة بيج
  static const Color surface = Color(0xFFFFFFFF); // أبيض نقي
  static const Color surfaceVariant = Color(0xFFF5EFE7); // بيج فاتح جداً
  
  // لون التراب الطبيعي
  static const Color earth = Color(0xFF8B7355); // تراب طبيعي
  static const Color earthLight = Color(0xFFB89968); // تراب فاتح
  static const Color earthDark = Color(0xFF6B5744); // تراب داكن
  
  // ألوان النصوص
  static const Color textPrimary = Color(0xFF3E2723); // بني داكن للنصوص الأساسية
  static const Color textSecondary = Color(0xFF6D4C41); // بني متوسط للنصوص الثانوية
  static const Color textTertiary = Color(0xFF8D6E63); // بني فاتح للنصوص المساعدة
  
  // ألوان الحالة
  static const Color success = Color(0xFF81A87E); // أخضر ترابي
  static const Color error = Color(0xFFB57C6F); // أحمر ترابي
  static const Color warning = Color(0xFFD4A574); // برتقالي ترابي
  static const Color info = Color(0xFF92A9BD); // أزرق ترابي
  
  // ألوان إضافية للتصميم
  static const Color divider = Color(0xFFE8DDD0); // خط فاصل بيج
  static const Color shadow = Color(0x1A3E2723); // ظل خفيف
  static const Color overlay = Color(0x4D3E2723); // طبقة شفافة
  
  // Gradient أنيق لون التراب
  static const LinearGradient earthGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC4A27C),
      Color(0xFFA58968),
      Color(0xFF8B7355),
    ],
  );
  
  // Gradient بيج فاتح
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF5EFE7),
    ],
  );
}
