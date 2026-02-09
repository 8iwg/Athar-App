import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as flutter_svg;
import '../core/theme/app_colors.dart';

class ElegantAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showLogo;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const ElegantAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showLogo = false,
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.textPrimary,
                ),
              Expanded(
                child: showLogo
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          flutter_svg.SvgPicture.asset(
                            'assets/images/logo.svg',
                            height: 36,
                            width: 36,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      )
                    : Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                        textAlign: showBackButton ? TextAlign.start : TextAlign.center,
                      ),
              ),
              if (actions != null) ...actions!,
              if (!showBackButton && actions == null)
                const SizedBox(width: 48), // للتوازن
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 12);
}
