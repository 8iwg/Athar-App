import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/spots_provider.dart';
import '../models/camping_spot.dart';
import '../models/report.dart';
import '../widgets/elegant_app_bar.dart';

class ModeratorScreen extends StatefulWidget {
  const ModeratorScreen({super.key});

  @override
  State<ModeratorScreen> createState() => _ModeratorScreenState();
}

class _ModeratorScreenState extends State<ModeratorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String ownerEmail = 'rshyizer+1@gmail.com';
  bool _isModerator = false;
  bool _isOwner = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkModeratorStatus();
    _enforceAccessControl();
  }

  // طبقة حماية إضافية - إغلاق الشاشة فوراً إذا لم يكن مصرحاً
  void _enforceAccessControl() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final authProvider = context.read<AuthProvider>();
      final email = authProvider.currentUser?.email;
      
      if (email == null) {
        Navigator.of(context).pushReplacementNamed('/main');
        return;
      }
      
      // السماح للمالك
      if (email == ownerEmail) return;
      
      // التحقق من قائمة المشرفين
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('moderators')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        
        if (snapshot.docs.isEmpty && mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      }
    });
  }

  Future<void> _checkModeratorStatus() async {
    final authProvider = context.read<AuthProvider>();
    final email = authProvider.currentUser?.email;
    
    if (email == null) {
      setState(() => _isLoading = false);
      return;
    }

    // التحقق من المالك
    if (email == ownerEmail) {
      setState(() {
        _isOwner = true;
        _isModerator = true;
        _isLoading = false;
      });
      return;
    }

    // التحقق من قائمة المشرفين
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('moderators')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      setState(() {
        _isModerator = snapshot.docs.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // التحقق من الصلاحية
    if (!_isModerator) {
      return Scaffold(
        appBar: const ElegantAppBar(
          title: 'غير مصرح',
          showBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 80, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'ليس لديك صلاحية للوصول',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'هذه الصفحة للمشرفين فقط',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: ElegantAppBar(
        title: 'لوحة الإشراف',
        showBackButton: true,
        actions: [
          if (_isOwner)
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/manage-moderators');
              },
              icon: const Icon(Icons.group_add),
              tooltip: 'إدارة المشرفين',
            ),
          Icon(Icons.admin_panel_settings, color: AppColors.primary),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'البوستات', icon: Icon(Icons.post_add)),
                Tab(text: 'البلاغات', icon: Icon(Icons.report)),
                Tab(text: 'أخطاء برمجية', icon: Icon(Icons.bug_report)),
                Tab(text: 'المحظورين', icon: Icon(Icons.block)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildReportsTab(),
                _buildBugReportsTab(),
                _buildBannedUsersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return Consumer<SpotsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.spots.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: AppColors.textTertiary.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('لا توجد بوستات', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.spots.length,
          itemBuilder: (context, index) {
            final spot = provider.spots[index];
            return _buildSpotCard(spot);
          },
        );
      },
    );
  }

  Widget _buildSpotCard(CampingSpot spot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: spot.imageUrls.isNotEmpty
                      ? Image.network(
                          spot.imageUrls.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: AppColors.surfaceVariant,
                              child: Icon(Icons.image_not_supported, color: AppColors.textTertiary),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: AppColors.surfaceVariant,
                          child: Icon(Icons.image, color: AppColors.textTertiary),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'بواسطة: ${spot.userName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${spot.region} - ${spot.city}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: AppColors.error),
                const SizedBox(width: 4),
                Text('${spot.likes}', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: AppColors.warning),
                const SizedBox(width: 4),
                Text('${spot.rating}', style: TextStyle(color: AppColors.textSecondary)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _banUser(spot.userId, spot.userName),
                  icon: Icon(Icons.block, color: Colors.red.shade900, size: 20),
                  label: Text('حظر المستخدم', style: TextStyle(color: Colors.red.shade900, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteSpot(spot),
                  icon: Icon(Icons.delete, color: AppColors.error, size: 20),
                  label: Text('حذف', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: AppColors.success.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('لا توجد بلاغات', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final report = Report.fromJson(doc.data() as Map<String, dynamic>);
            return _buildReportCard(report, doc.id);
          },
        );
      },
    );
  }

  Widget _buildReportCard(Report report, String docId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.error.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.reason,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'البوست: ${report.spotName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'المبلغ: ${report.reporterName}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (report.additionalInfo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.additionalInfo!,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(report.createdAt),
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _viewReportedSpot(report.spotId),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('عرض البوست'),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteReport(docId),
                      icon: Icon(Icons.delete, size: 18, color: AppColors.error),
                      label: Text('حذف البلاغ', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    
    // للتواريخ القديمة: عرض التاريخ الكامل
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _deleteSpot(CampingSpot spot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${spot.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<SpotsProvider>().deleteSpot(spot.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم حذف البوست' : 'فشل الحذف'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteReport(String reportId) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حذف البلاغ'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحذف: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildBugReportsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bug_reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: AppColors.success),
                const SizedBox(height: 16),
                Text(
                  'لا توجد أخطاء برمجية مبلّغ عنها',
                  style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final bugData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final bugId = bugData['id'] ?? '';
            final title = bugData['title'] ?? '';
            final description = bugData['description'] ?? '';
            final steps = bugData['steps'] ?? '';
            final reporterName = bugData['reporterName'] ?? 'مجهول';
            final reporterEmail = bugData['reporterEmail'] ?? '';
            final status = bugData['status'] ?? 'جديد';
            final resolved = bugData['resolved'] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          resolved ? Icons.check_circle : Icons.bug_report,
                          color: resolved ? AppColors.success : Colors.red.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: resolved ? AppColors.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: resolved ? AppColors.success : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (description.isNotEmpty) ...[
                      Text(
                        'الوصف:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                    ],
                    if (steps.isNotEmpty) ...[
                      Text(
                        'خطوات إعادة المشكلة:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(steps, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                    ],
                    const Divider(),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          reporterName,
                          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                        if (reporterEmail.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '($reporterEmail)',
                            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          ),
                        ],
                        const Spacer(),
                        if (!resolved)
                          TextButton.icon(
                            onPressed: () => _markBugAsResolved(bugId),
                            icon: Icon(Icons.check, color: AppColors.success, size: 18),
                            label: Text('تم الحل', style: TextStyle(color: AppColors.success, fontSize: 12)),
                          ),
                        TextButton.icon(
                          onPressed: () => _deleteBugReport(bugId),
                          icon: Icon(Icons.delete, color: AppColors.error, size: 18),
                          label: Text('حذف', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markBugAsResolved(String bugId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bug_reports')
          .doc(bugId)
          .update({
        'status': 'تم الحل',
        'resolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث حالة الخطأ'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التحديث: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteBugReport(String bugId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا البلاغ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('bug_reports').doc(bugId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم حذف البلاغ'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل الحذف: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _banUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red.shade900, size: 28),
            const SizedBox(width: 8),
            const Text('حظر المستخدم نهائياً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد حظر المستخدم "$userName" نهائياً؟',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ تحذير:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• لن يتمكن من تسجيل الدخول للتطبيق\n• سيتم حذف جميع منشوراته\n• هذا الإجراء نهائي',
                    style: TextStyle(fontSize: 13, color: Colors.red.shade900),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
            ),
            child: const Text('حظر نهائياً'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // إضافة المستخدم لقائمة المحظورين
        await FirebaseFirestore.instance.collection('banned_users').doc(userId).set({
          'userId': userId,
          'userName': userName,
          'bannedAt': FieldValue.serverTimestamp(),
          'bannedBy': _isOwner ? 'المالك' : 'مشرف',
        });

        // حذف جميع منشورات المستخدم
        final userPosts = await FirebaseFirestore.instance
            .collection('spots')
            .where('userId', isEqualTo: userId)
            .get();

        for (var doc in userPosts.docs) {
          await doc.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حظر المستخدم "$userName" نهائياً'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل الحظر: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildBannedUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banned_users')
          .orderBy('bannedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: AppColors.success),
                const SizedBox(height: 16),
                Text(
                  'لا يوجد مستخدمين محظورين',
                  style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final bannedData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final userId = bannedData['userId'] ?? '';
            final userName = bannedData['userName'] ?? 'مجهول';
            final bannedBy = bannedData['bannedBy'] ?? '';
            final bannedAt = bannedData['bannedAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade900,
                  child: const Icon(Icons.block, color: Colors.white),
                ),
                title: Text(
                  userName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'تم الحظر بواسطة: $bannedBy',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if (bannedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'التاريخ: ${_formatDate(bannedAt.toDate())}',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
                trailing: _isOwner
                    ? IconButton(
                        onPressed: () => _unbanUser(userId, userName),
                        icon: Icon(Icons.restore, color: AppColors.success),
                        tooltip: 'إلغاء الحظر',
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _unbanUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.restore, color: AppColors.success, size: 28),
            const SizedBox(width: 8),
            const Text('إلغاء الحظر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل تريد إلغاء حظر المستخدم "$userName"؟\n\nسيتمكن من تسجيل الدخول مرة أخرى.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('إلغاء الحظر'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('banned_users').doc(userId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إلغاء حظر المستخدم "$userName"'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل إلغاء الحظر: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _viewReportedSpot(String spotId) async {
    final spot = context.read<SpotsProvider>().spots.firstWhere(
      (s) => s.id == spotId,
      orElse: () => context.read<SpotsProvider>().spots.first,
    );
    
    // يمكن إضافة التنقل لصفحة تفاصيل البوست هنا
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(spot.name),
        content: Text(spot.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
