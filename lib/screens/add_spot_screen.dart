import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../models/camping_spot.dart';
import '../providers/spots_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/elegant_app_bar.dart';
import '../data/saudi_cities.dart';
import '../services/cloudinary_service.dart';
import '../services/ad_service.dart';

class AddSpotScreen extends StatefulWidget {
  final List<XFile>? images;
  final LatLng? initialLocation;

  const AddSpotScreen({
    super.key,
    this.images,
    this.initialLocation,
  });

  @override
  State<AddSpotScreen> createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends State<AddSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prosController = TextEditingController();
  final _consController = TextEditingController();
  final _warningsController = TextEditingController();
  final _searchController = TextEditingController();
  final List<XFile> _selectedImages = [];
  Position? _currentPosition;
  String? _selectedLocationName;
  bool _isLoading = false;
  bool _isAgreed = false; // التعهد بصحة البيانات
  double _rating = 1.0;
  List<String> _pros = [];
  List<String> _cons = [];
  List<String> _warnings = [];
  List<String> _selectedAccessOptions = []; // خيارات الوصول المختارة
  String _selectedCategory = 'كشتة';
  
  // دالة تنظيف المدخلات من HTML و XSS
  String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')  // إزالة HTML tags
        .replaceAll(RegExp(r'script', caseSensitive: false), '')  // حماية من XSS
        .trim();
  }
  
  // خيارات صعوبة الوصول
  final List<Map<String, dynamic>> _accessOptions = [
    {'text': 'سيارة صغيرة لا تدخل', 'icon': Icons.no_transfer_rounded, 'value': 'سيارة صغيرة لا تدخل'},
    {'text': 'يحتاج دبل خفيف', 'icon': Icons.terrain_rounded, 'value': 'يحتاج دبل خفيف'},
    {'text': 'يحتاج دبل ثقيل', 'icon': Icons.agriculture_rounded, 'value': 'يحتاج دبل ثقيل'},
    {'text': 'طرق وعرة', 'icon': Icons.warning_rounded, 'value': 'طرق وعرة'},
    {'text': 'صخور كثيرة', 'icon': Icons.landscape_rounded, 'value': 'صخور كثيرة'},
    {'text': 'مرتفع جداً', 'icon': Icons.landscape_rounded, 'value': 'مرتفع جداً'},
    {'text': 'مكان غير نظيف', 'icon': Icons.cleaning_services_rounded, 'value': 'مكان غير نظيف'},
  ];
  String? _selectedRegion;
  String? _selectedCity;
  
  final List<String> _categories = [
    'جبال', 'كشتة', 'وديان', 'شواطئ', 'غابات', 'مرتفعات',
  ];

  @override
  void initState() {
    super.initState();
    
    // إذا كانت هناك صور من الكاميرا، نضيفها
    if (widget.images != null && widget.images!.isNotEmpty) {
      _selectedImages.addAll(widget.images!);
    }
    
    // إذا كان هناك موقع محدد، نستخدمه
    if (widget.initialLocation != null) {
      _currentPosition = Position(
        latitude: widget.initialLocation!.latitude,
        longitude: widget.initialLocation!.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } else {
      // إذا لم يكن هناك موقع، نطلبه
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() {});
    } catch (e) {
      debugPrint('خطأ في الحصول على الموقع: $e');
    }
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 3) {
      _showError('الحد الأقصى 3 صور فقط');
      return;
    }
    
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      // حساب عدد الصور المتبقية المسموح بها
      final remainingSlots = 3 - _selectedImages.length;
      final imagesToAdd = images.take(remainingSlots).toList();
      
      if (images.length > remainingSlots) {
        _showError('تم إضافة $remainingSlots صور فقط. الحد الأقصى 3 صور');
      }
      
      setState(() {
        _selectedImages.addAll(imagesToAdd);
      });
    } catch (e) {
      _showError('فشل اختيار الصور');
    }
  }

  Future<void> _submitSpot() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      _showError('يرجى اختيار صورة واحدة على الأقل');
      return;
    }

    if (_currentPosition == null) {
      _showError('لم نتمكن من الحصول على موقعك الحالي');
      return;
    }

    // التحقق من الحد اليومي
    final authProvider = context.read<AuthProvider>();
    final canPost = await _checkDailyLimit(authProvider.userId);
    if (!canPost) {
      return; // الرسالة ستظهر من _checkDailyLimit
    }

    // 🎯 عرض الإعلان قبل النشر
    await AdService().showInterstitialAdIfReady(
      onAdClosed: () => _performPublish(authProvider),
      frequency: 2, // كل مرتين (أقل من دلني لأن النشر أقل تكراراً)
    );
  }

  Future<void> _performPublish(AuthProvider authProvider) async {
    setState(() => _isLoading = true);
    debugPrint('🚀 بدأت عملية إضافة المكان...');

    try {
      final spotsProvider = context.read<SpotsProvider>();

      debugPrint('📸 بدأ رفع الصور... عدد الصور: ${_selectedImages.length}');
      
      // رفع الصور إلى Cloudinary
      final imageUrls = await CloudinaryService.uploadMultipleImages(_selectedImages);
      
      if (imageUrls.isEmpty) {
        debugPrint('❌ فشل رفع جميع الصور');
        _showError('فشل رفع الصور، حاول مرة أخرى');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('✅ تم رفع ${imageUrls.length} صورة بنجاح');
      debugPrint('📝 إنشاء كائن المكان...');

      final spot = CampingSpot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        imageUrls: imageUrls,
        userId: authProvider.userId,
        userName: authProvider.userName,
        createdAt: DateTime.now(),
        rating: _rating,
        pros: _pros,
        cons: _cons,
        warnings: _warnings,
        accessDifficulty: _selectedAccessOptions,
        category: _selectedCategory,
        region: _selectedRegion!,
        city: _selectedCity!,
      );

      debugPrint('💾 حفظ المكان في Firestore...');
      final success = await spotsProvider.addSpot(spot);
      
      if (success && mounted) {
        debugPrint('✅ تم حفظ المكان بنجاح');
        
        // تحديث آخر وقت نشر للمستخدم
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(authProvider.userId)
              .update({'lastPostTime': DateTime.now().toIso8601String()});
          debugPrint('✅ تم تحديث وقت آخر نشر');
        } catch (e) {
          debugPrint('⚠️ خطأ في تحديث وقت النشر: $e');
        }
        
        debugPrint('🔄 جلب البيانات المحدثة...');
        
        // تحديث البيانات قبل الرجوع
        await spotsProvider.fetchSpots();
        
        debugPrint('🎉 اكتملت العملية بنجاح!');
        
        // الرجوع للصفحة الرئيسية
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم إضافة المكان بنجاح! ✨'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        debugPrint('❌ فشل حفظ المكان في Firestore');
        _showError('فشل إضافة المكان');
      }
    } catch (e) {
      debugPrint('❌ خطأ عام: $e');
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) {
        debugPrint('🏁 انتهت العملية');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  /// التحقق من الحد اليومي للنشر (بوست واحد كل 24 ساعة)
  Future<bool> _checkDailyLimit(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return true; // مستخدم جديد، اسمح له
      
      final userData = userDoc.data();
      
      // التحقق من المشرف - المشرفين لا حد لهم
      final isModerator = userData?['isModerator'] ?? false;
      final ownerEmail = 'rshyizer+1@gmail.com';
      final isOwner = userData?['email'] == ownerEmail;
      
      if (isModerator || isOwner) {
        return true; // المشرفين والمالك يمكنهم النشر بدون حد
      }
      
      if (userData == null || userData['lastPostTime'] == null) {
        return true; // لم ينشر من قبل
      }
      
      final lastPostTime = DateTime.parse(userData['lastPostTime'] as String);
      final now = DateTime.now();
      final difference = now.difference(lastPostTime);
      
      if (difference.inHours >= 24) {
        return true; // مر 24 ساعة، يمكنه النشر
      }
      
      // حساب الوقت المتبقي
      final remainingHours = 24 - difference.inHours;
      final remainingMinutes = (24 * 60 - difference.inMinutes) % 60;
      final nextPostTime = lastPostTime.add(const Duration(hours: 24));
      
      // عرض رسالة توضيحية
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('حد النشر اليومي'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'يمكنك نشر بوست واحد فقط كل 24 ساعة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('آخر بوست: ${_formatDateTime(lastPostTime)}'),
                const SizedBox(height: 8),
                Text('الوقت المتبقي: $remainingHours ساعة و $remainingMinutes دقيقة'),
                const SizedBox(height: 8),
                Text(
                  'يمكنك النشر مرة أخرى في: ${_formatDateTime(nextPostTime)}',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
      
      return false;
    } catch (e) {
      debugPrint('خطأ في التحقق من الحد اليومي: $e');
      return true; // في حالة الخطأ، اسمح بالنشر
    }
  }
  
  /// تنسيق التاريخ والوقت
  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'م' : 'ص';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} - $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ElegantAppBar(
        title: 'إضافة مكان جديد',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildRegionCitySection(),
              const SizedBox(height: 24),
              _buildCategorySection(),
              const SizedBox(height: 24),
              _buildRatingSection(),
              const SizedBox(height: 24),
              
              // قسم صعوبة الوصول
              _buildAccessOptionsSection(),
              const SizedBox(height: 24),
              _buildProsSection(),
              const SizedBox(height: 24),
              _buildConsSection(),
              const SizedBox(height: 24),
              _buildWarningsList(),
              const SizedBox(height: 16),
              _buildLocationInfo(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صور المكان',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (_selectedImages.isEmpty)
          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'إضافة صور للمكان',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'يمكنك إضافة حتى 3 صور',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: FutureBuilder<Uint8List>(
                              future: _selectedImages[index].readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.surfaceVariant,
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 48,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                                return Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                icon: const Icon(Icons.close, color: Colors.white),
                                iconSize: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${index + 1}/${_selectedImages.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectedImages.length < 3 ? _pickImages : null,
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 20,
                  ),
                  label: Text(_selectedImages.length < 3 
                      ? 'إضافة المزيد (${_selectedImages.length}/3)'
                      : 'تم الوصول للحد الأقصى (3/3)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.primary,
                    disabledForegroundColor: AppColors.textTertiary,
                    side: BorderSide(
                      color: _selectedImages.length < 5 
                          ? AppColors.primary.withOpacity(0.5)
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'اسم المكان',
        hintText: 'مثال: شعيب الخزام',
        prefixIcon: Icon(Icons.place),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال اسم المكان';
        }
        if (value.length > 100) {
          return 'الاسم طويل جداً (الحد الأقصى 100 حرف)';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'وصف المكان',
        hintText: 'اكتب وصفاً للمكان والمميزات...',
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال وصف للمكان';
        }
        if (value.length > 1000) {
          return 'الوصف طويل جداً (الحد الأقصى 1000 حرف)';
        }
        return null;
      },
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _currentPosition != null
                        ? Icons.location_on
                        : Icons.location_off,
                    color: _currentPosition != null
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPosition != null
                              ? 'تم تحديد الموقع'
                              : 'جارٍ تحديد الموقع...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedLocationName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedLocationName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (_currentPosition != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'عرض: ${_currentPosition!.latitude.toStringAsFixed(4)} • طول: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showLocationSearchSheet,
                      icon: Icon(Icons.search_rounded, size: 20),
                      label: Text('بحث عن موقع'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: Icon(Icons.my_location_rounded, size: 20),
                      label: Text('موقعي الحالي'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: BorderSide(color: AppColors.success),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _showLocationSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationSearchSheet(
        onLocationSelected: (lat, lng, name) {
          setState(() {
            _currentPosition = Position(
              latitude: lat,
              longitude: lng,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
            _selectedLocationName = name;
          });
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        // صندوق التعهد
        GestureDetector(
          onTap: () {
            setState(() {
              _isAgreed = !_isAgreed;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAgreed 
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isAgreed 
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.textTertiary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, left: 8),
                  child: Icon(
                    _isAgreed 
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: _isAgreed 
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.7,
                        fontFamily: 'Cairo',
                      ),
                      children: [
                        TextSpan(
                          text: 'أتعهد بكل أمانة وصدق ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const TextSpan(
                          text: 'أن المعلومات المقدمة عن هذا المكان صحيحة ودقيقة، وأدرك أن هذه المعلومات هي ',
                        ),
                        TextSpan(
                          text: 'أمانة ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        const TextSpan(
                          text: 'لأن الناس ستعتمد عليها في تخطيط رحلاتهم.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // زر الإضافة
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isLoading || !_isAgreed) ? null : _submitSpot,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: _isAgreed ? AppColors.primary : Colors.grey.shade300,
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: _isAgreed ? 2 : 0,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isAgreed) ...[
                        Icon(
                          Icons.add_location_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _isAgreed ? 'إضافة المكان' : 'يرجى الموافقة على التعهد أولاً',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isAgreed ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegionCitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'المنطقة والمدينة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '*',
                style: TextStyle(color: AppColors.error, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // اختيار المنطقة
          DropdownButtonFormField<String>(
            value: _selectedRegion,
            decoration: InputDecoration(
              hintText: 'اختر المنطقة',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: SaudiCities.getRegions().map((region) {
              return DropdownMenuItem(
                value: region,
                child: Text(region),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRegion = value;
                _selectedCity = null; // إعادة تعيين المدينة
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // اختيار المدينة
          DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: InputDecoration(
              hintText: _selectedRegion == null ? 'اختر المنطقة أولاً' : 'اختر المدينة',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _selectedRegion == null
                ? []
                : SaudiCities.getCitiesByRegion(_selectedRegion!).map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
            onChanged: _selectedRegion == null
                ? null
                : (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أثر المكان',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.earthGradient : null,
                    color: isSelected ? null : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppColors.divider,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
              Text(
                'التقييم',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // عرض النجوم حسب التقييم
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isFilled = index < _rating.floor();
              final isHalf = index < _rating && index >= _rating.floor();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isFilled ? Icons.star_rounded : (isHalf ? Icons.star_half_rounded : Icons.star_outline_rounded),
                  size: 32,
                  color: (isFilled || isHalf) ? AppColors.warning : AppColors.divider,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // السلايدر
          Slider(
            value: _rating,
            min: 1.0,
            max: 5.0,
            divisions: 40, // يسمح بـ 0.1 فروق
            activeColor: AppColors.warning,
            inactiveColor: AppColors.divider,
            label: _rating.toStringAsFixed(1),
            onChanged: (value) {
              setState(() => _rating = value);
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${_rating.toStringAsFixed(1)} من 5.0',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
              Text(
                'معلومات الوصول',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'حدد طبيعة الطريق ومتطلبات الوصول للمكان',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _accessOptions.map((option) {
              final isSelected = _selectedAccessOptions.contains(option['value']);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedAccessOptions.remove(option['value']);
                    } else {
                      _selectedAccessOptions.add(option['value']);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    option['text'],
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 24),
              const SizedBox(width: 8),
              Text(
                'الإيجابيات',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '${_pros.length}/5',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prosController,
                  decoration: InputDecoration(
                    hintText: 'أضف ميزة إيجابية',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _addPro(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _pros.length >= 5 ? null : _addPro,
                icon: Icon(
                  Icons.add_circle_rounded,
                  color: _pros.length >= 5 ? AppColors.divider : AppColors.success,
                  size: 32,
                ),
              ),
            ],
          ),
          if (_pros.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._pros.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.value),
                      ),
                      GestureDetector(
                        onTap: () => _removePro(entry.key),
                        child: Icon(Icons.close, size: 20, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildConsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              Text(
                'السلبيات',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '${_cons.length}/5',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _consController,
                  decoration: InputDecoration(
                    hintText: 'أضف نقطة سلبية',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _addCon(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _cons.length >= 5 ? null : _addCon,
                icon: Icon(
                  Icons.add_circle_rounded,
                  color: _cons.length >= 5 ? AppColors.divider : AppColors.error,
                  size: 32,
                ),
              ),
            ],
          ),
          if (_cons.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._cons.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.value),
                      ),
                      GestureDetector(
                        onTap: () => _removeCon(entry.key),
                        child: Icon(Icons.close, size: 20, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
              Text(
                'تنبيهات مهمة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '${_warnings.length}/5',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _warningsController,
                  decoration: InputDecoration(
                    hintText: 'مثل: المحطة بعيدة، لا يوجد إشارة',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _addWarning(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _warnings.length >= 5 ? null : _addWarning,
                icon: Icon(
                  Icons.add_circle_rounded,
                  color: _warnings.length >= 5 ? AppColors.divider : AppColors.warning,
                  size: 32,
                ),
              ),
            ],
          ),
          if (_warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._warnings.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.value),
                      ),
                      GestureDetector(
                        onTap: () => _removeWarning(entry.key),
                        child: Icon(Icons.close, size: 20, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _addPro() {
    if (_pros.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الحد الأقصى 5 إيجابيات'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    if (_prosController.text.trim().isNotEmpty) {
      setState(() {
        _pros.add(_prosController.text.trim());
        _prosController.clear();
      });
    }
  }

  void _removePro(int index) {
    setState(() => _pros.removeAt(index));
  }

  void _addCon() {
    if (_cons.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الحد الأقصى 5 سلبيات'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    if (_consController.text.trim().isNotEmpty) {
      setState(() {
        _cons.add(_consController.text.trim());
        _consController.clear();
      });
    }
  }

  void _removeCon(int index) {
    setState(() => _cons.removeAt(index));
  }

  void _addWarning() {
    if (_warnings.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الحد الأقصى 5 تنبيهات'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final warning = _warningsController.text.trim();
    if (warning.isEmpty) return;

    setState(() {
      _warnings.add(warning);
      _warningsController.clear();
    });
  }

  void _removeWarning(int index) {
    setState(() => _warnings.removeAt(index));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prosController.dispose();
    _consController.dispose();
    _warningsController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Location Search Sheet Widget
class _LocationSearchSheet extends StatefulWidget {
  final Function(double lat, double lng, String name) onLocationSelected;
  
  const _LocationSearchSheet({required this.onLocationSelected});
  
  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  
  final List<Map<String, dynamic>> _saudiLocations = [
    {'name': 'الرياض', 'lat': 24.7136, 'lng': 46.6753},
    {'name': 'جدة', 'lat': 21.5433, 'lng': 39.1728},
    {'name': 'مكة المكرمة', 'lat': 21.4225, 'lng': 39.8262},
    {'name': 'المدينة المنورة', 'lat': 24.5247, 'lng': 39.5692},
    {'name': 'الدمام', 'lat': 26.4367, 'lng': 50.1039},
    {'name': 'الطائف', 'lat': 21.2703, 'lng': 40.4150},
    {'name': 'تبوك', 'lat': 28.3835, 'lng': 36.5662},
    {'name': 'بريدة', 'lat': 26.3260, 'lng': 43.9750},
    {'name': 'خميس مشيط', 'lat': 18.3067, 'lng': 42.7289},
    {'name': 'نجران', 'lat': 17.5650, 'lng': 44.2289},
    {'name': 'جازان', 'lat': 16.8892, 'lng': 42.5511},
    {'name': 'حائل', 'lat': 27.5236, 'lng': 41.7008},
    {'name': 'ينبع', 'lat': 24.0899, 'lng': 38.0618},
    {'name': 'الأحساء', 'lat': 25.4295, 'lng': 49.6175},
    {'name': 'أبها', 'lat': 18.2164, 'lng': 42.5053},
    {'name': 'عرعر', 'lat': 30.9753, 'lng': 41.0381},
    {'name': 'سكاكا', 'lat': 29.9697, 'lng': 40.2064},
    {'name': 'الجبيل', 'lat': 27.0144, 'lng': 49.6542},
    {'name': 'القطيف', 'lat': 26.5205, 'lng': 50.0088},
    {'name': 'الخبر', 'lat': 26.2172, 'lng': 50.1971},
    {'name': 'الظهران', 'lat': 26.2361, 'lng': 50.1553},
    {'name': 'الخرج', 'lat': 24.1550, 'lng': 47.3118},
    {'name': 'القصيم', 'lat': 26.3260, 'lng': 43.9750},
    {'name': 'عنيزة', 'lat': 26.0833, 'lng': 43.9611},
    {'name': 'الرس', 'lat': 25.8697, 'lng': 43.4978},
  ];
  
  void searchLocation(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }
    
    setState(() {
      isSearching = true;
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      final filtered = _saudiLocations.where((location) {
        return location['name'].toString().contains(query);
      }).toList();
      
      setState(() {
        searchResults = filtered;
        isSearching = false;
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'بحث عن موقع',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: searchLocation,
                decoration: InputDecoration(
                  hintText: 'ابحث عن مدينة أو منطقة...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            searchLocation('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Results
            Expanded(
              child: isSearching
                  ? Center(child: CircularProgressIndicator())
                  : searchResults.isEmpty && _searchController.text.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 80,
                                color: AppColors.textTertiary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ابحث عن مدينة أو منطقة',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_saudiLocations.length} موقع متاح',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : searchResults.isEmpty
                          ? Center(
                              child: Text(
                                'لم يتم العثور على نتائج',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final location = searchResults[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  color: AppColors.surfaceVariant,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      widget.onLocationSelected(
                                        location['lat'] as double,
                                        location['lng'] as double,
                                        location['name'] as String,
                                      );
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تم تحديد موقع: ${location['name']}'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    },
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    title: Text(
                                      location['name'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'عرض: ${(location['lat'] as double).toStringAsFixed(4)} • طول: ${(location['lng'] as double).toStringAsFixed(4)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
