import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String _cloudName = 'du1runneq';
  static const String _uploadPreset = 'athar_unsigned';
  
  /// رفع صورة إلى Cloudinary
  static Future<String?> uploadImage(XFile image) async {
    try {
      if (kDebugMode) {
        debugPrint('📤 بدء رفع الصورة إلى Cloudinary...');
      }
      
      // قراءة البيانات
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      if (kDebugMode) {
        debugPrint('📦 حجم الصورة: ${bytes.length} بايت');
      }
      
      // إنشاء FormData
      final formData = FormData.fromMap({
        'file': 'data:image/jpeg;base64,$base64Image',
        'upload_preset': _uploadPreset,
        'folder': 'athar/spots',
      });
      
      // رفع إلى Cloudinary
      final dio = Dio();
      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      
      if (response.statusCode == 200) {
        final secureUrl = response.data['secure_url'];
        if (kDebugMode) {
          debugPrint('✅ تم رفع الصورة: $secureUrl');
        }
        return secureUrl;
      } else {
        if (kDebugMode) {
          debugPrint('❌ فشل الرفع: ${response.statusCode}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ خطأ في رفع الصورة: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return null;
    }
  }
  
  /// رفع عدة صور
  static Future<List<String>> uploadMultipleImages(List<XFile> images) async {
    final List<String> urls = [];
    
    for (int i = 0; i < images.length; i++) {
      if (kDebugMode) {
        debugPrint('⬆️ رفع الصورة ${i + 1}/${images.length}');
      }
      final url = await uploadImage(images[i]);
      if (url != null) {
        urls.add(url);
      }
    }
    
    return urls;
  }
  
  // ⚠️ تنبيه أمني:
  // تم إزالة دالة حذف الصور لحماية API Secret
  // يجب استخدام Cloud Function بدلاً من ذلك
  
  /// حذف صورة من Cloudinary (يتطلب Cloud Function)
  /// TODO: قم بإنشاء Cloud Function لحذف الصور بشكل آمن
  static Future<bool> deleteImage(String imageUrl) async {
    // سيتم تنفيذ هذا عبر Cloud Function لحماية API keys
    debugPrint('⚠️ حذف الصور يتطلب Cloud Function - الميزة غير مفعلة');
    // في الوقت الحالي، الصور لن تُحذف من Cloudinary
    // ولكن سيتم حذف الروابط من Firestore فقط
    return true;
  }
  
  /// حذف عدة صور
  static Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }
}

