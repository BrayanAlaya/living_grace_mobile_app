import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.muted,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
