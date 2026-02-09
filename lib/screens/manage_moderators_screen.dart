import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/elegant_app_bar.dart';

class ManageModeratorsScreen extends StatefulWidget {
  const ManageModeratorsScreen({super.key});

  @override
  State<ManageModeratorsScreen> createState() => _ManageModeratorsScreenState();
}

class _ManageModeratorsScreenState extends State<ManageModeratorsScreen> {
  final String ownerEmail = 'rshyizer+1@gmail.com';
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    // التحقق من أن المستخدم هو المالك
    if (authProvider.currentUser?.email != ownerEmail) {
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
                'للمالك فقط',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const ElegantAppBar(
        title: 'إدارة المشرفين',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // إضافة مشرف جديد
          Container(
            margin: const EdgeInsets.all(16),
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
                  'إضافة مشرف جديد',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'أدخل إيميل المشرف',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addModerator,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // قائمة المشرفين
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('moderators')
                  .orderBy('addedAt', descending: true)
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
                        Icon(
                          Icons.supervisor_account,
                          size: 80,
                          color: AppColors.textTertiary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا يوجد مشرفين',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final email = data['email'] ?? '';
                    final addedAt = data['addedAt'] != null
                        ? DateTime.parse(data['addedAt'])
                        : DateTime.now();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          email,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'تمت الإضافة: ${_formatDate(addedAt)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () => _deleteModerator(doc.id, email),
                          icon: Icon(Icons.delete, color: AppColors.error),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addModerator() async {
    final email = _emailController.text.trim().toLowerCase();
    
    if (email.isEmpty) {
      _showError('يرجى إدخال الإيميل');
      return;
    }

    if (!email.contains('@')) {
      _showError('يرجى إدخال إيميل صحيح');
      return;
    }

    if (email == ownerEmail) {
      _showError('أنت المالك بالفعل');
      return;
    }

    try {
      // التحقق من عدم وجود المشرف
      final existing = await FirebaseFirestore.instance
          .collection('moderators')
          .where('email', isEqualTo: email)
          .get();

      if (existing.docs.isNotEmpty) {
        _showError('المشرف موجود بالفعل');
        return;
      }

      // إضافة المشرف
      await FirebaseFirestore.instance.collection('moderators').add({
        'email': email,
        'addedAt': DateTime.now().toIso8601String(),
        'addedBy': ownerEmail,
      });

      _emailController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تمت إضافة المشرف بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('فشل إضافة المشرف: $e');
    }
  }

  Future<void> _deleteModerator(String docId, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المشرف:\n$email'),
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

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('moderators')
            .doc(docId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم حذف المشرف'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        _showError('فشل الحذف: $e');
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
