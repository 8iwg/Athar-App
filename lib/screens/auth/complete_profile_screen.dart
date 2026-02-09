import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';
import '../../data/saudi_cities.dart';
import '../../providers/auth_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  
  String? _selectedRegion;
  String? _selectedCity;
  XFile? _avatarImage;
  Uint8List? _avatarBytes;
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  bool _shouldRemoveAvatar = false; // متغير جديد لتتبع إذا تم حذف الأفاتار

  @override
  void initState() {
    super.initState();
    // تعبئة البيانات الحالية إذا وجدت
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user != null) {
      _usernameController.text = user.username;
      _nicknameController.text = user.nickname;
      _selectedRegion = user.region;
      _selectedCity = user.city;
    }
    
    // مراقبة تغييرات اسم المستخدم
    _usernameController.addListener(_checkUsernameAvailability);
  }
  
  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    final authProvider = context.read<AuthProvider>();
    
    // لا نفحص إذا كان نفس اليوزرنيم الحالي
    if (username == authProvider.currentUser?.username) {
      setState(() {
        _isUsernameAvailable = true;
        _isCheckingUsername = false;
      });
      return;
    }
    
    if (username.isEmpty || username.length < 3) {
      setState(() => _isUsernameAvailable = null);
      return;
    }
    
    setState(() => _isCheckingUsername = true);
    
    try {
      final isAvailable = await authProvider.isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          _isUsernameAvailable = isAvailable;
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingUsername = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_checkUsernameAvailability);
    _usernameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      _shouldRemoveAvatar = false; // نلغي علامة الحذف عند اختيار صورة جديدة
      
      // عرض محرر الصورة
      if (mounted) {
        final editedBytes = await Navigator.push<Uint8List>(
          context,
          MaterialPageRoute(
            builder: (context) => _ImageEditorScreen(imageBytes: bytes),
            fullscreenDialog: true,
          ),
        );
        
        if (editedBytes != null) {
          setState(() {
            _avatarImage = image;
            _avatarBytes = editedBytes;
          });
        }
      }
    }
  }

  void _removeAvatar() {
    setState(() {
      _avatarImage = null;
      _avatarBytes = null;
      _shouldRemoveAvatar = true; // نضع علامة أنه تم حذف الأفاتار
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRegion == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار المنطقة والمدينة')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      
      print('🔄 بدء الحفظ...');
      print('Username: ${_usernameController.text.trim()}');
      print('Nickname: ${_nicknameController.text.trim()}');
      print('Avatar: ${_avatarImage != null ? "موجودة" : "لا توجد"}');
      
      final user = authProvider.currentUser;
      await authProvider.updateUserProfile(
        username: _usernameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        region: _selectedRegion!,
        city: _selectedCity!,
        avatarFile: _avatarImage,
        removeAvatar: _shouldRemoveAvatar,
      );
      
      print('✅ تم الحفظ بنجاح');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // إذا كان التعديل من صفحة موجودة، نرجع للخلف
        // وإلا نروح للصفحة الرئيسية
        final authProvider = context.read<AuthProvider>();
        if (authProvider.currentUser?.region.isNotEmpty == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حفظ التعديلات بنجاح ✓', style: GoogleFonts.cairo()),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    } catch (e) {
      print('❌ خطأ في الحفظ: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ البيانات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: user?.region.isNotEmpty == true 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          user?.region.isEmpty == true ? 'إكمال الملف الشخصي' : 'تعديل الملف الشخصي',
          style: GoogleFonts.cairo(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // رسالة ترحيبية
                    if (user?.region.isEmpty == true) ...[
                      Text(
                        'مرحباً ${user?.nickname ?? "بك"}! 👋',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أكمل بياناتك الشخصية للمتابعة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),

                    // صورة الملف الشخصي
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.earthGradient,
                                image: _avatarBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(_avatarBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : (!_shouldRemoveAvatar && user?.avatarUrl != null)
                                        ? DecorationImage(
                                            image: NetworkImage(user!.avatarUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                              ),
                              child: _avatarBytes == null && (_shouldRemoveAvatar || user?.avatarUrl == null)
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.8),
                                    )
                                  : null,
                            ),
                          ),
                          // زر الكاميرا
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadow,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // زر الحذف
                          if (!_shouldRemoveAvatar && (_avatarBytes != null || user?.avatarUrl != null))
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: GestureDetector(
                                onTap: _removeAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.shadow,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.delete_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                const SizedBox(height: 32),

                // اسم المستخدم (Username)
                _buildUsernameField(),
                const SizedBox(height: 16),

                // الاسم المستعار (Nickname)
                _buildTextField(
                  controller: _nicknameController,
                  label: 'الاسم المستعار',
                  hint: 'الاسم الذي سيظهر للآخرين',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الاسم المستعار';
                    }
                    if (value.length < 2) {
                      return 'الاسم يجب أن يكون حرفين على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // اختيار المنطقة
                _buildDropdown(
                  label: 'المنطقة',
                  value: _selectedRegion,
                  items: SaudiCities.regionsWithCities.keys.toList(),
                  icon: Icons.location_city_rounded,
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value;
                      _selectedCity = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // اختيار المدينة
                if (_selectedRegion != null)
                  _buildDropdown(
                    label: 'المدينة',
                    value: _selectedCity,
                    items: SaudiCities.regionsWithCities[_selectedRegion!] ?? [],
                    icon: Icons.location_on_rounded,
                    onChanged: (value) {
                      setState(() => _selectedCity = value);
                    },
                  ),

                const SizedBox(height: 32),

                // زر الحفظ
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          user?.region.isEmpty == true ? 'حفظ والمتابعة' : 'حفظ التعديلات',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اسم المستخدم (Username)',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          style: GoogleFonts.cairo(color: AppColors.textPrimary),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
            LengthLimitingTextInputFormatter(20),
          ],
          onChanged: (value) {
            // تنبيه للحروف الكبيرة
            if (value.contains(RegExp(r'[A-Z]'))) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ اسم المستخدم يجب أن يكون حروف صغيرة فقط (a-z)', style: GoogleFonts.cairo()),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            // تنبيه للحروف العربية
            if (value.contains(RegExp(r'[\u0600-\u06FF]'))) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ اسم المستخدم يجب أن يكون بالإنجليزية فقط', style: GoogleFonts.cairo()),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الرجاء إدخال اسم المستخدم';
            }
            if (value.length < 3) {
              return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
            }
            if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
              return 'فقط حروف إنجليزية صغيرة وأرقام و_';
            }
            if (_isUsernameAvailable == false) {
              return 'اسم المستخدم محجوز بالفعل';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'مثال: sultan_95',
            hintStyle: GoogleFonts.cairo(color: AppColors.textTertiary),
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.primary),
            suffixIcon: _isCheckingUsername
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _isUsernameAvailable == true
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : _isUsernameAvailable == false
                        ? const Icon(Icons.error, color: AppColors.error)
                        : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
        if (_isUsernameAvailable == false) ...[
          const SizedBox(height: 4),
          Text(
            '❌ اسم المستخدم محجوز',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ] else if (_isUsernameAvailable == true && _usernameController.text.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '✓ اسم المستخدم متاح',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.success,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: GoogleFonts.cairo(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(color: AppColors.textTertiary),
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: Text(
              'اختر $label',
              style: GoogleFonts.cairo(color: AppColors.textTertiary),
            ),
            style: GoogleFonts.cairo(color: AppColors.textPrimary),
            dropdownColor: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// محرر صور بسيط باستخدام InteractiveViewer
class _ImageEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const _ImageEditorScreen({required this.imageBytes});

  @override
  State<_ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<_ImageEditorScreen> {
  final TransformationController _controller = TransformationController();
  double _scale = 1.0;
  Offset _position = Offset.zero;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Uint8List?> _getCroppedImage() async {
    try {
      // تحميل الصورة الأصلية
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;
      
      // حساب الأبعاد والموضع للقص
      final matrix = _controller.value;
      final scaleX = matrix.getMaxScaleOnAxis();
      final translateX = matrix.getTranslation().x;
      final translateY = matrix.getTranslation().y;
      
      // حجم الصورة المعروضة
      final displayWidth = originalImage.width.toDouble();
      final displayHeight = originalImage.height.toDouble();
      
      // حساب حجم القص (مربع 512x512)
      final cropSize = 512;
      
      // حساب الموضع النسبي للقص
      final centerX = displayWidth / 2;
      final centerY = displayHeight / 2;
      
      final cropX = ((centerX - translateX / scaleX) - cropSize / (2 * scaleX)).clamp(0.0, displayWidth - cropSize / scaleX);
      final cropY = ((centerY - translateY / scaleX) - cropSize / (2 * scaleX)).clamp(0.0, displayHeight - cropSize / scaleX);
      
      // إنشاء recorder للرسم
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // رسم الجزء المقصوص
      final srcRect = Rect.fromLTWH(
        cropX,
        cropY,
        cropSize / scaleX,
        cropSize / scaleX,
      );
      final dstRect = Rect.fromLTWH(0, 0, cropSize.toDouble(), cropSize.toDouble());
      
      canvas.drawImageRect(originalImage, srcRect, dstRect, Paint());
      
      // تحويل إلى صورة
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(cropSize, cropSize);
      
      // تحويل إلى bytes
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('خطأ في قص الصورة: $e');
      return widget.imageBytes; // إرجاع الصورة الأصلية في حالة الخطأ
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('تعديل الصورة', style: GoogleFonts.cairo(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary, size: 28),
            onPressed: () async {
              final croppedBytes = await _getCroppedImage();
              if (mounted && croppedBytes != null) {
                Navigator.pop(context, croppedBytes);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InteractiveViewer(
                    transformationController: _controller,
                    minScale: 0.5,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(100),
                    onInteractionUpdate: (details) {
                      setState(() {
                        _scale = _controller.value.getMaxScaleOnAxis();
                        _position = Offset(
                          _controller.value.getTranslation().x,
                          _controller.value.getTranslation().y,
                        );
                      });
                    },
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // دائرة التحديد
                  IgnorePointer(
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black87,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'التكبير/التصغير',
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      '${(_scale * 100).toInt()}%',
                      style: GoogleFonts.cairo(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                      onPressed: () {
                        final currentMatrix = _controller.value.clone();
                        final currentScale = currentMatrix.getMaxScaleOnAxis();
                        final newScale = (currentScale * 0.9).clamp(0.5, 4.0);
                        final scaleRatio = newScale / currentScale;
                        
                        currentMatrix.scale(scaleRatio, scaleRatio);
                        _controller.value = currentMatrix;
                        setState(() {
                          _scale = newScale;
                        });
                      },
                    ),
                    Expanded(
                      child: Slider(
                        value: _scale,
                        min: 0.5,
                        max: 4.0,
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.grey,
                        onChanged: (value) {
                          final currentMatrix = _controller.value.clone();
                          final currentScale = currentMatrix.getMaxScaleOnAxis();
                          final scaleRatio = value / currentScale;
                          
                          currentMatrix.scale(scaleRatio, scaleRatio);
                          _controller.value = currentMatrix;
                          setState(() {
                            _scale = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      onPressed: () {
                        final currentMatrix = _controller.value.clone();
                        final currentScale = currentMatrix.getMaxScaleOnAxis();
                        final newScale = (currentScale * 1.1).clamp(0.5, 4.0);
                        final scaleRatio = newScale / currentScale;
                        
                        currentMatrix.scale(scaleRatio, scaleRatio);
                        _controller.value = currentMatrix;
                        setState(() {
                          _scale = newScale;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'حرك الصورة لتحديد الجزء الذي تريده داخل الدائرة',
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
