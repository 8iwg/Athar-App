import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/spots_provider.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onBackToHome;
  
  const ProfileScreen({super.key, this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // إذا كان زائر، اعرض رسالة تسجيل الدخول
        if (authProvider.isGuestMode) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              automaticallyImplyLeading: true,
              title: Text(
                'الملف الشخصي',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'سجل دخولك لترى ملفك الشخصي',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'أنشئ حساب لتتمكن من مشاركة الأماكن المفضلة وحفظ منشوراتك',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('تسجيل الدخول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signup');
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('إنشاء حساب جديد'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        final user = authProvider.currentUser;
        
        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              automaticallyImplyLeading: true,
              title: Text(
                'الملف الشخصي',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'سجل دخولك لترى ملفك الشخصي',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'أنشئ حساب لتتمكن من مشاركة الأماكن المفضلة وحفظ منشوراتك',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('تسجيل الدخول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signup');
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('إنشاء حساب جديد'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            automaticallyImplyLeading: true,
            title: Text(
              'الملف الشخصي',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                      content: Text('هل تريد تسجيل الخروج؟', style: GoogleFonts.cairo()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('إلغاء', style: GoogleFonts.cairo()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('تسجيل الخروج', style: GoogleFonts.cairo(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true && context.mounted) {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                },
                icon: Icon(Icons.logout, color: AppColors.error),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // صورة الملف الشخصي
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary,
                    backgroundImage: user.avatarUrl != null 
                        ? NetworkImage(user.avatarUrl!) 
                        : null,
                    child: user.avatarUrl == null
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // اسم المستخدم
                  Text(
                    user.nickname,
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Username
                  Text(
                    '@${user.username}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // الإحصائيات
                  Consumer<SpotsProvider>(
                    builder: (context, spotsProvider, _) {
                      final userSpots = spotsProvider.spots.where((s) => s.userId == user.id).toList();
                      final postsCount = userSpots.length;
                      
                      // حساب مجموع الإعجابات من كل المنشورات
                      final totalLikes = userSpots.fold<int>(
                        0,
                        (sum, spot) => sum + spot.likes,
                      );
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.1),
                              AppColors.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(
                              context,
                              postsCount.toString(),
                              'المنشورات',
                              Icons.location_on_rounded,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.divider,
                            ),
                            _buildStat(
                              context,
                              totalLikes.toString(),
                              'الإعجابات',
                              Icons.favorite_rounded,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Bio
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        user.bio!,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  // الأزرار
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/complete-profile');
                    },
                    icon: const Icon(Icons.edit),
                    label: Text('تعديل الملف الشخصي', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // زر لوحة الإشراف (للمودريتر فقط)
                  _buildModeratorButton(context, authProvider),
                  
                  const SizedBox(height: 16),
                  
                  // معلومات إضافية
                  _buildInfoCard(
                    context,
                    icon: Icons.email_outlined,
                    title: 'البريد الإلكتروني',
                    value: user.email,
                  ),
                  _buildInfoCard(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'المنطقة',
                    value: user.region,
                  ),
                  _buildInfoCard(
                    context,
                    icon: Icons.location_city_outlined,
                    title: 'المدينة',
                    value: user.city,
                  ),
                  _buildInfoCard(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'عضو منذ',
                    value: DateFormat('MMMM yyyy', 'ar').format(user.createdAt),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  IconData _getProviderIcon(authProvider) {
    switch (authProvider.toString().split('.').last) {
      case 'apple':
        return Icons.apple;
      case 'google':
        return Icons.g_mobiledata_rounded;
      default:
        return Icons.email;
    }
  }

  Widget _buildStat(BuildContext context, String count, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeratorButton(BuildContext context, AuthProvider authProvider) {
    final email = authProvider.currentUser?.email;
    if (email == null) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: _checkModeratorAccess(email),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/moderator');
          },
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text('لوحة الإشراف'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkModeratorAccess(String email) async {
    // التحقق من المالك
    if (email == 'rshyizer+1@gmail.com') return true;

    // التحقق من قائمة المشرفين
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('moderators')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
