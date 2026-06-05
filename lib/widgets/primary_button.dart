import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double? width;
  final double height;
  final bool outlined;
  const PrimaryButton({super.key, required this.label, this.onPressed,
    this.isLoading = false, this.icon, this.color, this.width,
    this.height = 50, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppColors.accentBlue;
    final child = isLoading
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: outlined ? btnColor : Colors.white))
        : icon != null
        ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: outlined ? btnColor : Colors.white),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w700, fontSize: 15, color: outlined ? btnColor : Colors.white)),
          ])
        : Text(label, style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w700, fontSize: 15, color: outlined ? btnColor : Colors.white));
    if (outlined) {
      return SizedBox(width: width ?? double.infinity, height: height,
        child: OutlinedButton(onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(side: BorderSide(color: btnColor, width: 1.5), foregroundColor: btnColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: child));
    }
    return SizedBox(width: width ?? double.infinity, height: height,
      child: ElevatedButton(onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: child));
  }
}
