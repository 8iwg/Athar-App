import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../models/camping_spot.dart';
import '../providers/auth_provider.dart';
import '../providers/spots_provider.dart';
import '../services/ad_service.dart';

class SpotFeedCard extends StatelessWidget {
  final CampingSpot spot;
  final VoidCallback onTap;

  const SpotFeedCard({
    super.key,
    required this.spot,
    required this.onTap,
  });

  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final hasImage = spot.imageUrls.isNotEmpty;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: hasImage
            ? _buildImageWidget(spot.imageUrls.first)
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildImageWidget(String url) {
    // إذا كان file:// نستخدم Image.memory أو Image.network
    // للويب نحتاج معالجة خاصة
    if (url.startsWith('file://')) {
      // على الويب، نعرض صورة مع معلومات
      return Container(
        color: AppColors.primary.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: AppColors.success,
            ),
            const SizedBox(height: 8),
            Text(
              'تم رفع الصورة',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              spot.name,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.landscape,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(
            'صورة المكان',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات الناشر
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // البحث عن معلومات الناشر
              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserInfo(spot.userId),
                builder: (context, snapshot) {
                  final userData = snapshot.data;
                  final nickname = userData?['nickname'] ?? 'مستخدم';
                  final avatarUrl = userData?['avatarUrl'];
                  
                  return Row(
                    children: [
                      // صورة الناشر
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Icon(Icons.person, size: 18, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      // اسم الناشر
                      Expanded(
                        child: Text(
                          nickname,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          
          // العنوان
          Text(
            spot.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          
          // الوصف
          Text(
            spot.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // التصنيف والتقييم
          Row(
            children: [
              // التصنيف
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  spot.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              // التقييم
              ...List.generate(5, (index) {
                return Icon(
                  index < spot.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: index < spot.rating ? AppColors.warning : AppColors.divider,
                );
              }),
              const SizedBox(width: 4),
              Text(
                spot.rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          
          // الإيجابيات والسلبيات والتنبيهات (اختصار)
          if (spot.pros.isNotEmpty || spot.cons.isNotEmpty || spot.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (spot.pros.isNotEmpty) 
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        '${spot.pros.length} إيجابيات',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                if (spot.cons.isNotEmpty) 
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel, size: 16, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        '${spot.cons.length} سلبيات',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                if (spot.warnings.isNotEmpty) 
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${spot.warnings.length} تنبيهات',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          
          // المنطقة
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'الرياض',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // الإحصائيات والأزرار
          Row(
            children: [
              // زر الإبلاغ
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final isGuest = auth.isGuestMode;
                  
                  return InkWell(
                    onTap: () {
                      if (isGuest) {
                        _showLoginRequiredDialog(context, 'للإبلاغ عن المنشورات');
                      } else {
                        _showReportDialog(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.report_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ابلاغ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(width: 8),
              
              // زر اللايك
              Consumer2<AuthProvider, SpotsProvider>(
                builder: (context, auth, spots, _) {
                  final userId = auth.currentUser?.id ?? '';
                  final isLiked = spot.likedBy.contains(userId);
                  final isGuest = auth.isGuestMode;
                  
                  return InkWell(
                    onTap: () {
                      if (isGuest) {
                        _showLoginRequiredDialog(context, 'للإعجاب بالمنشورات');
                      } else {
                        spots.toggleLike(spot.id, userId);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isLiked ? AppColors.error : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${spot.likes}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(width: 8),
              
              // زر المفضلة (القلب)
              Consumer2<SpotsProvider, AuthProvider>(
                builder: (context, spots, auth, _) {
                  final isFavorite = spots.isFavorite(spot.id);
                  final isGuest = auth.isGuestMode;
                  
                  return InkWell(
                    onTap: () {
                      if (isGuest) {
                        _showLoginRequiredDialog(context, 'لإضافة المنشورات للمفضلة');
                      } else {
                        spots.toggleFavorite(spot.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 22,
                        color: isFavorite ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 8),
              
              // زر المحفوظات (Bookmark)
              Consumer2<SpotsProvider, AuthProvider>(
                builder: (context, spots, auth, _) {
                  final isSaved = spots.isSaved(spot.id);
                  final isGuest = auth.isGuestMode;
                  
                  return InkWell(
                    onTap: () {
                      if (isGuest) {
                        _showLoginRequiredDialog(context, 'لحفظ المنشورات');
                      } else {
                        spots.toggleSaved(spot.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 22,
                        color: isSaved ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
              
              const Spacer(),
              
              // زر دلني عليه (مع إعلان)
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final isGuest = auth.isGuestMode;
                  
                  return ElevatedButton.icon(
                    onPressed: () {
                      if (isGuest) {
                        _showLoginRequiredDialog(context, 'للحصول على التوجيه للمكان');
                      } else {
                        _showAdAndNavigate(context);
                      }
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('دلني عليه'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// عرض إعلان قبل التنقل
  void _showAdAndNavigate(BuildContext context) async {
    // محاولة عرض الإعلان
    await AdService().showInterstitialAdIfReady(
      onAdClosed: () {
        // بعد إغلاق الإعلان، عرض قائمة خيارات التنقل
        _showNavigationOptions(context);
      },
      frequency: 3, // عرض الإعلان كل 3 مرات
    );
  }
  
  void _showNavigationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            Text(
              'اختر تطبيق التنقل',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Google Maps
            _buildNavigationOption(
              context,
              icon: Icons.map_rounded,
              title: 'Google Maps',
              subtitle: 'مسار مفصل مع تعليمات صوتية',
              color: const Color(0xFF4285F4),
              onTap: () {
                Navigator.pop(context);
                _openGoogleMaps();
              },
            ),
            
            const SizedBox(height: 12),
            
            // Waze
            _buildNavigationOption(
              context,
              icon: Icons.navigation_rounded,
              title: 'Waze',
              subtitle: 'تنبيهات فورية عن الزحام والمرور',
              color: const Color(0xFF33CCFF),
              onTap: () {
                Navigator.pop(context);
                _openWaze();
              },
            ),
            
            const SizedBox(height: 12),
            
            // Apple Maps
            _buildNavigationOption(
              context,
              icon: Icons.explore_rounded,
              title: 'Apple Maps',
              subtitle: 'خرائط آبل لأجهزة iOS',
              color: const Color(0xFF007AFF),
              onTap: () {
                Navigator.pop(context);
                _openAppleMaps();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavigationOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
  
  Future<void> _openGoogleMaps() async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    final name = Uri.encodeComponent(spot.name);
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name&travelmode=driving&hl=ar'
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
  
  Future<void> _openWaze() async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    final url = Uri.parse(
      'https://waze.com/ul?ll=$lat,$lng&navigate=yes&lang=ar'
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
  
  Future<void> _openAppleMaps() async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    final url = Uri.parse(
      'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d&t=m'
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildStat({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'الإبلاغ عن المنشور',
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportOption(
              context,
              icon: Icons.location_off,
              title: 'موقع خاطئ أو خارج التصنيف',
              description: 'المكان غير مطابق للتصنيف المحدد',
            ),
            _buildReportOption(
              context,
              icon: Icons.image_not_supported,
              title: 'صور غير مناسبة',
              description: 'صور مسيئة أو غير واضحة',
            ),
            _buildReportOption(
              context,
              icon: Icons.warning,
              title: 'معلومات مضللة',
              description: 'محتوى غير صحيح أو خادع',
            ),
            _buildReportOption(
              context,
              icon: Icons.person_off,
              title: 'مكان خاص بدون إذن',
              description: 'ملكية خاصة تم نشرها دون موافقة',
            ),
            _buildReportOption(
              context,
              icon: Icons.block,
              title: 'محتوى مخالف آخر',
              description: 'مخالفة أخرى للقوانين',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _submitReport(context, title);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport(BuildContext context, String reason) {
    // هنا يمكن إضافة كود حفظ البلاغ في Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال البلاغ: $reason'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تسجيل الدخول مطلوب',
          textAlign: TextAlign.right,
        ),
        content: Text(
          'يجب تسجيل الدخول $action',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}
