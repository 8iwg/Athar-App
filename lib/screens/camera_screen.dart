import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../core/theme/app_colors.dart';
import 'location_picker_screen.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // مكان الكاميرا - سيتم تفعيلها لاحقاً
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  size: 100,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'التقط صورة للموقع',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'اضغط على الزر أدناه للتصوير',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // زر الإغلاق
          Positioned(
            top: 50,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
            ),
          ),
          
          // زر التصوير/رفع صورة
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // رفع من المعرض
                IconButton(
                  onPressed: () => _pickFromGallery(context),
                  icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                ),
                
                const SizedBox(width: 40),
                
                // زر التصوير
                GestureDetector(
                  onTap: () => _takePhoto(context),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        // التقاط الموقع تلقائياً
        LatLng? location;
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          location = LatLng(position.latitude, position.longitude);
        } catch (e) {
          // في حالة فشل الحصول على الموقع، سيتم طلبه لاحقاً
          debugPrint('فشل الحصول على الموقع: $e');
        }

        // الانتقال لشاشة تحديد الموقع
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPickerScreen(
              images: [photo],
              initialLocation: location,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التقاط الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> photos = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (photos.isNotEmpty) {
        // تحديد أقصى عدد 5 صور
        List<XFile> selectedPhotos = photos.take(5).toList();
        
        if (photos.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم اختيار أول 5 صور فقط (الحد الأقصى)'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // التقاط الموقع تلقائياً
        LatLng? location;
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          location = LatLng(position.latitude, position.longitude);
        } catch (e) {
          // في حالة فشل الحصول على الموقع، سيتم طلبه لاحقاً
          debugPrint('فشل الحصول على الموقع: $e');
        }

        // الانتقال لشاشة تحديد الموقع
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPickerScreen(
              images: selectedPhotos,
              initialLocation: location,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الصور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
