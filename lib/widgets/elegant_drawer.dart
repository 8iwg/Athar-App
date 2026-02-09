import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as flutter_svg;
import '../core/theme/app_colors.dart';

class ElegantDrawer extends StatelessWidget {
  final Function(String?)? onCategorySelected;
  final Function(bool)? onFavoritesToggle;
  final VoidCallback? onSettingsTap;
  
  const ElegantDrawer({
    super.key,
    this.onCategorySelected,
    this.onFavoritesToggle,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    flutter_svg.SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'أثر',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // الأقسام
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.explore,
                      title: 'استكشف الكل',
                      onTap: () {
                        onCategorySelected?.call(null);
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.terrain,
                      title: 'جبال',
                      onTap: () {
                        onCategorySelected?.call('جبال');
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.wb_sunny,
                      title: 'كشتة',
                      onTap: () {
                        onCategorySelected?.call('كشتة');
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.water,
                      title: 'وديان',
                      onTap: () {
                        onCategorySelected?.call('وديان');
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.beach_access,
                      title: 'شواطئ',
                      onTap: () {
                        onCategorySelected?.call('شواطئ');
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.park,
                      title: 'غابات',
                      onTap: () {
                        onCategorySelected?.call('غابات');
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.landscape,
                      title: 'مرتفعات',
                      onTap: () {
                        onCategorySelected?.call('مرتفعات');
                        Navigator.pop(context);
                      },
                    ),
                    
                    const Divider(height: 32),
                    
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings,
                      title: 'الإعدادات',
                      onTap: () {
                        Navigator.pop(context);
                        onSettingsTap?.call();
                      },
                    ),
                  ],
                ),
              ),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'atharmaps.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
