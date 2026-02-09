import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../models/camping_spot.dart';
import '../providers/spots_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/elegant_app_bar.dart';
import 'dart:io';
import 'dart:typed_data';

class SpotDetailsScreen extends StatelessWidget {
  final CampingSpot spot;

  const SpotDetailsScreen({super.key, required this.spot});

  Future<void> _openInMaps() async {
    final lat = spot.latitude;
    final lng = spot.longitude;
    final name = Uri.encodeComponent(spot.name);

    // Google Maps مع التنقل والتعليمات الصوتية بالعربي
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name&travelmode=driving&hl=ar'
    );
    
    // Apple Maps
    final appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d&t=m'
    );
    
    // Waze مع اللغة العربية
    final wazeUrl = Uri.parse(
      'https://waze.com/ul?ll=$lat,$lng&navigate=yes&lang=ar'
    );

    try {
      // محاولة فتح Google Maps أولاً
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } 
      // إذا لم يتوفر، محاولة فتح Apple Maps
      else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(
          appleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      }
      // إذا لم يتوفر، محاولة فتح Waze
      else if (await canLaunchUrl(wazeUrl)) {
        await launchUrl(
          wazeUrl,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // في حالة الخطأ، لا نفعل شيء
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImages(context),
                _buildContent(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigateButton(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(spot.name),
    );
  }

  Widget _buildImages(BuildContext context) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: spot.imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = spot.imageUrls[index];
          
          return CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.surfaceVariant,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surfaceVariant,
              child: const Icon(Icons.error),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  spot.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _buildRatingChip(),
            ],
          ),
          const SizedBox(height: 12),
          _buildUserInfo(context),
          const SizedBox(height: 8),
          _buildLikeButton(context),
          const Divider(height: 32),
          
          // القسم والمنطقة
          _buildInfoRow(context, Icons.category, 'القسم', spot.category),
          const SizedBox(height: 12),
          _buildInfoRow(context, Icons.location_city, 'المنطقة', spot.region ?? 'غير محدد'),
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.location_on, 'المدينة', spot.city ?? 'غير محدد'),
          
          const Divider(height: 32),
          
          Text(
            'الوصف',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            spot.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          
          // صعوبة الوصول
          if (spot.accessDifficulty.isNotEmpty) ...[
            Text(
              'معلومات الوصول',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
            ),
            const SizedBox(height: 12),
            _buildAccessDifficultySection(),
            const SizedBox(height: 24),
          ],
          
          // التنبيهات
          if (spot.warnings.isNotEmpty) ...[
            Text(
              'تنبيهات مهمة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildWarningsSection(),
            const SizedBox(height: 24),
          ],
          
          // الإيجابيات
          if (spot.pros.isNotEmpty) ...[
            Text(
              'مميزات المكان',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
            ),
            const SizedBox(height: 12),
            _buildPositivesSection(),
            const SizedBox(height: 24),
          ],
          
          // السلبيات
          if (spot.cons.isNotEmpty) ...[
            Text(
              'عيوب المكان',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
            ),
            const SizedBox(height: 12),
            _buildNegativesSection(),
            const SizedBox(height: 24),
          ],
          
          _buildLocationCard(context),
          const SizedBox(height: 100), // مساحة للزر السفلي
        ],
      ),
    );
  }

  Widget _buildRatingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(
            spot.rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildWarningsSection() {
    return Column(
      children: spot.warnings.map((warning) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  warning,
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccessDifficultySection() {
    return Column(
      children: spot.accessDifficulty.map((access) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.terrain_rounded, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  access,
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPositivesSection() {
    return Column(
      children: spot.pros.map((positive) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  positive,
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNegativesSection() {
    return Column(
      children: spot.cons.map((negative) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  negative,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primary,
          radius: 16,
          child: Text(
            spot.userName[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          spot.userName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          '•',
          style: TextStyle(color: AppColors.textTertiary),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDate(spot.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }

  Widget _buildLikeButton(BuildContext context) {
    return Consumer2<SpotsProvider, AuthProvider>(
      builder: (context, spotsProvider, authProvider, child) {
        final isLiked = spot.likedBy.contains(authProvider.userId);
        
        return Column(
          children: [
            IconButton(
              onPressed: () {
                spotsProvider.toggleLike(spot.id, authProvider.userId);
              },
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? AppColors.error : AppColors.textSecondary,
                size: 28,
              ),
            ),
            Text(
              '${spot.likes}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الموقع',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${spot.latitude.toStringAsFixed(6)}, ${spot.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigateButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: _openInMaps,
                icon: const Icon(Icons.navigation),
                label: const Text('وجهني إلى المكان'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _reportSpot(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: AppColors.error),
                ),
                child: Icon(Icons.report, color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportSpot(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
    // التحقق من تسجيل الدخول
    if (authProvider.isGuestMode || authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يجب تسجيل الدخول أولاً للتبليغ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String? selectedReason;
    final reasons = [
      'محتوى غير لائق',
      'معلومات خاطئة',
      'موقع خطير',
      'صور مخالفة',
      'سبب آخر',
    ];
    
    final additionalInfoController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.report, color: AppColors.error),
              const SizedBox(width: 8),
              const Text('تبليغ عن البوست'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر سبب التبليغ:'),
                const SizedBox(height: 12),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() => selectedReason = value);
                  },
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: additionalInfoController,
                  decoration: const InputDecoration(
                    labelText: 'معلومات إضافية (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('إرسال التبليغ'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedReason != null) {
      try {
        // التحقق مرة أخرى من المستخدم
        final currentUser = authProvider.currentUser;
        if (currentUser == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('خطأ: لم يتم العثور على بيانات المستخدم'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // حفظ البلاغ مع جميع البيانات المطلوبة
        final reportDoc = FirebaseFirestore.instance.collection('reports').doc();
        final reportData = {
          'id': reportDoc.id,
          'reportType': 'spot',
          'spotId': spot.id,
          'spotName': spot.name,
          'reporterId': currentUser.id,
          'reporterName': currentUser.nickname,
          'reportedBy': currentUser.id,
          'reason': selectedReason,
          'additionalInfo': additionalInfoController.text.trim().isNotEmpty
              ? additionalInfoController.text.trim()
              : null,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await reportDoc.set(reportData);

        // حفظ إشعار بسيط للمشرفين
        try {
          final notificationDoc = FirebaseFirestore.instance.collection('moderator_notifications').doc();
          await notificationDoc.set({
            'id': notificationDoc.id,
            'type': 'report',
            'title': 'بلاغ جديد',
            'body': 'بلاغ على: ${spot.name} - السبب: $selectedReason',
            'spotId': spot.id,
            'reportId': reportDoc.id,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
        } catch (e) {
          debugPrint('فشل حفظ الإشعار: $e');
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم إرسال التبليغ بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        debugPrint('خطأ في إرسال البلاغ: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل إرسال التبليغ: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
