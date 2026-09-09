import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_layout.dart';

/// Layout del home: distinto al de auth (preparado para el diseño futuro).
class HomeLayout extends StatelessWidget {
  const HomeLayout({
    super.key,
    required this.child,
    this.title,
  });

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      backgroundColor: AppColors.white,
      statusBarBrightness: Brightness.dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
