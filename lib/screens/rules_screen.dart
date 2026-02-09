import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'القوانين والإرشادات',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRuleCard(
              icon: Icons.location_on,
              title: 'التصنيف الصحيح',
              description:
                  'يجب اختيار التصنيف المناسب للمكان (كشتة، مخيم، استراحة، إلخ). ممنوع نشر أماكن خارج إطار التصنيفات المحددة.',
            ),
            const SizedBox(height: 16),
            _buildRuleCard(
              icon: Icons.camera_alt,
              title: 'الصور والمحتوى',
              description:
                  'يجب أن تكون الصور واضحة وتمثل المكان الفعلي. ممنوع نشر صور مسيئة أو غير لائقة.',
            ),
            const SizedBox(height: 16),
            _buildRuleCard(
              icon: Icons.description,
              title: 'الوصف الدقيق',
              description:
                  'يجب كتابة وصف واضح ودقيق للمكان مع ذكر الإيجابيات والسلبيات والتنبيهات المهمة.',
            ),
            const SizedBox(height: 16),
            _buildRuleCard(
              icon: Icons.block,
              title: 'المحتوى المحظور',
              description:
                  'ممنوع نشر:\n• أماكن خاصة بدون إذن أصحابها\n• مواقع عسكرية أو ممنوعة\n• محتوى مسيء أو تمييزي\n• معلومات مضللة',
            ),
            const SizedBox(height: 16),
            _buildRuleCard(
              icon: Icons.location_city,
              title: 'المواقع الجغرافية',
              description:
                  'يجب أن تكون الإحداثيات دقيقة وتمثل الموقع الصحيح. عدم نشر مواقع في مناطق محمية بدون تصريح.',
            ),
            const SizedBox(height: 16),
            _buildRuleCard(
              icon: Icons.report,
              title: 'الإبلاغ عن المخالفات',
              description:
                  'إذا وجدت منشور مخالف، يمكنك الإبلاغ عنه باستخدام زر الإبلاغ. سيتم مراجعة البلاغات واتخاذ الإجراء المناسب.',
            ),
            const SizedBox(height: 16),
            _buildRuleCard(
              icon: Icons.gavel,
              title: 'عواقب المخالفة',
              description:
                  'المخالفات المتكررة قد تؤدي إلى:\n• حذف المنشورات\n• تعليق الحساب مؤقتاً\n• إيقاف الحساب نهائياً في الحالات الخطيرة',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'شكراً لالتزامك بالقوانين ومساعدتنا في بناء مجتمع آمن ومفيد للجميع',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
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

  Widget _buildRuleCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
