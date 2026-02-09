import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'rules_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onBackToHome;
  
  const SettingsScreen({super.key, this.onBackToHome});

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth) {
    final TextEditingController confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade900, size: 28),
            const SizedBox(width: 8),
            const Text(
              'تحذير: حذف الحساب',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سيتم حذف جميع بياناتك نهائياً بما في ذلك:',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildWarningItem('• جميع البوستات التي أضفتها'),
            _buildWarningItem('• جميع التعليقات والتقييمات'),
            _buildWarningItem('• قائمة المفضلة'),
            _buildWarningItem('• معلومات الحساب الشخصية'),
            const SizedBox(height: 16),
            const Text(
              'هذا الإجراء لا يمكن التراجع عنه!',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'اكتب "DELETE" للتأكيد:',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text.trim() == 'DELETE') {
                Navigator.pop(context);
                _deleteAccount(context, auth);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى كتابة "DELETE" للتأكيد'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'حذف نهائياً',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, AuthProvider auth) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final userId = auth.currentUser?.id;
      if (userId == null) {
        Navigator.pop(context);
        return;
      }

      // 1. Delete all user's spots
      final spotsSnapshot = await FirebaseFirestore.instance
          .collection('spots')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in spotsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Delete user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();

      // 3. Delete auth account and sign out
      await auth.deleteAccount();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Navigate to login
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف حسابك بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حذف الحساب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: onBackToHome != null ? IconButton(
          onPressed: onBackToHome,
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
        ) : null,
        automaticallyImplyLeading: false,
        title: Text(
          'الإعدادات',
          style: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 10),
            
            const SizedBox(height: 24),
            
            _buildSection(
              context,
              title: 'الحساب',
              items: [
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    // إذا كان زائر أو لم يسجل دخول
                    if (auth.isGuestMode || auth.currentUser == null) {
                      return _buildSettingItem(
                        context,
                        icon: Icons.person_add,
                        title: 'سجل دخولك',
                        subtitle: 'للوصول لجميع الميزات',
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      );
                    }
                    return _buildSettingItem(
                      context,
                      icon: Icons.person,
                      title: 'معلومات الحساب',
                      onTap: () {
                        Navigator.pushNamed(context, '/complete-profile');
                      },
                    );
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.lock,
                  title: 'الخصوصية والأمان',
                  onTap: () {
                    _showPrivacyDialog(context);
                  },
                ),
                Consumer<ThemeProvider>(
                  builder: (context, theme, _) => _buildSettingItem(
                    context,
                    icon: Icons.notifications,
                    title: 'الإشعارات',
                    trailing: Switch(
                      value: theme.notificationsEnabled,
                      onChanged: (value) => theme.toggleNotifications(),
                      activeColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            
            _buildSection(
              context,
              title: 'التطبيق',
              items: [
                _buildSettingItem(
                  context,
                  icon: Icons.language,
                  title: 'اللغة',
                  subtitle: 'العربية',
                  onTap: () {},
                ),
                Consumer<ThemeProvider>(
                  builder: (context, theme, _) => _buildSettingItem(
                    context,
                    icon: Icons.palette,
                    title: 'المظهر',
                    subtitle: theme.isDarkMode ? 'داكن' : 'فاتح',
                    trailing: Switch(
                      value: theme.isDarkMode,
                      onChanged: (value) => theme.toggleTheme(),
                      activeColor: AppColors.primary,
                    ),
                  ),
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.gavel,
                  title: 'القوانين والإرشادات',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RulesScreen()),
                    );
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.info,
                  title: 'عن التطبيق',
                  subtitle: 'الإصدار 1.0.0',
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
            
            _buildSection(
              context,
              title: 'الدعم',
              items: [
                _buildSettingItem(
                  context,
                  icon: Icons.help,
                  title: 'مركز المساعدة',
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'support@atharmaps.com',
                      query: 'subject=طلب مساعدة - أثر&body=مرحبا،%0A%0Aالرجاء كتابة مشكلتك هنا...',
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('لم يتمكن من فتح بريد الإلكتروني'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.feedback,
                  title: 'إرسال ملاحظات',
                  onTap: () {
                    _showFeedbackDialog(context);
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.bug_report,
                  title: 'التبليغ عن خطأ برمجي',
                  onTap: () {
                    _showBugReportDialog(context);
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.star,
                  title: 'قيّم التطبيق',
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                // إخفاء زر تسجيل الخروج إذا كان المستخدم زائر أو غير مسجل
                if (auth.isGuestMode || auth.currentUser == null) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => auth.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('تسجيل الخروج'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _showDeleteAccountDialog(context, auth),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('حذف الحساب نهائياً'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade900,
                        side: BorderSide(color: Colors.red.shade900, width: 2),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الخصوصية والأمان'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPrivacyItem(
                icon: Icons.lock_outline,
                title: 'حماية البيانات',
                description: 'جميع بياناتك محمية ومشفرة',
              ),
              const SizedBox(height: 16),
              _buildPrivacyItem(
                icon: Icons.visibility_off,
                title: 'خصوصية الموقع',
                description: 'لا نشارك موقعك إلا بإذنك',
              ),
              const SizedBox(height: 16),
              _buildPrivacyItem(
                icon: Icons.security,
                title: 'الأمان',
                description: 'نستخدم أحدث وسائل الأمان لحمايتك',
              ),
              const SizedBox(height: 16),
              _buildPrivacyItem(
                icon: Icons.delete_outline,
                title: 'حق الحذف',
                description: 'يمكنك حذف بياناتك في أي وقت',
              ),
            ],
          ),
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

  Widget _buildPrivacyItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    String selectedType = 'مشكلة تقنية';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إرسال ملاحظات'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نوع الملاحظة:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    'مشكلة تقنية',
                    'اقتراح تحسين',
                    'شكوى',
                    'أخرى',
                  ].map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('التفاصيل:'),
                const SizedBox(height: 8),
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'اكتب ملاحظاتك هنا...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (feedbackController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('الرجاء كتابة ملاحظاتك'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // إرسال الملاحظة عبر الإيميل
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'feedback@atharmaps.com',
                  query: 'subject=$selectedType - أثر&body=${Uri.encodeComponent(feedbackController.text)}',
                );

                Navigator.pop(context);

                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('شكراً على ملاحظاتك! ❤️'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لم يتمكن من فتح بريد الإلكتروني'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.primary.withOpacity(0.95),
                AppColors.earth.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // شعار التطبيق
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.landscape_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // اسم التطبيق
                  const Text(
                    'أثر',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Rubik',
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // الإصدار
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'الإصدار 1.0.0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // الوصف
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      'توجيه السعوديين والقادمين للسعودية لأفضل أماكن التنزه والترفيه مع الأهل والأصدقاء',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.8,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // المميزات
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeature(
                        icon: Icons.attach_money_rounded,
                        text: 'مجاني',
                      ),
                      _buildFeature(
                        icon: Icons.volunteer_activism,
                        text: 'خدمة مجتمعية',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // رسالة نهائية
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'نقدم لكم هذه الخدمة بكل حب ❤️\nلخدمة مجتمعنا الغالي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppColors.earth,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // رابط الموقع الرسمي
                  GestureDetector(
                    onTap: () async {
                      final Uri url = Uri.parse('https://atharmaps.com/');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'atharmaps.com',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // زر الإغلاق
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'حسناً',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController stepsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.bug_report, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 8),
            const Text(
              'التبليغ عن خطأ برمجي',
              style: TextStyle(fontFamily: 'Rubik', fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان المشكلة',
                  hintText: 'مثال: التطبيق يتوقف عند إضافة صورة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'وصف المشكلة',
                  hintText: 'اشرح المشكلة بالتفصيل...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stepsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'خطوات إعادة المشكلة',
                  hintText: '1. افتح التطبيق\n2. اضغط على...\n3. المشكلة تحدث',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Rubik', fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('يرجى كتابة عنوان المشكلة'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              try {
                final authProvider = context.read<AuthProvider>();
                final bugDoc = FirebaseFirestore.instance.collection('bug_reports').doc();
                
                await bugDoc.set({
                  'id': bugDoc.id,
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'steps': stepsController.text.trim(),
                  'reporterId': authProvider.userId,
                  'reporterName': authProvider.userName,
                  'reporterEmail': authProvider.currentUser?.email ?? '',
                  'createdAt': FieldValue.serverTimestamp(),
                  'status': 'جديد',
                  'resolved': false,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم إرسال التبليغ بنجاح، شكراً لك!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل إرسال التبليغ: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('إرسال', style: TextStyle(fontFamily: 'Rubik', fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String text,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
