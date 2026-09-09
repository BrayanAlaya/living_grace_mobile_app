import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class LivingGraceLogo extends StatelessWidget {
  const LivingGraceLogo({
    super.key,
    this.color = AppColors.black,
    this.livingFontSize = 28,
    this.graceFontSize = 56,
  });

  final Color color;
  final double livingFontSize;
  final double graceFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Living',
          style: GoogleFonts.playfairDisplay(
            fontSize: livingFontSize,
            fontWeight: FontWeight.w500,
            height: 1,
            letterSpacing: -0.5,
            color: color,
          ),
        ),
        Text(
          'Grace',
          style: GoogleFonts.playfairDisplay(
            fontSize: graceFontSize,
            fontWeight: FontWeight.w600,
            height: 0.92,
            letterSpacing: -1.5,
            color: color,
          ),
        ),
      ],
    );
  }
}
