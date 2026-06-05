import 'package:flutter/material.dart';

class AppColors {
  static const Color bgPrimary    = Color(0xFFF5F7FA);
  static const Color bgSecondary  = Color(0xFFFFFFFF);
  static const Color bgCard       = Color(0xFFFFFFFF);
  static const Color bgInput      = Color(0xFFF1F4F9);
  static const Color accentBlue   = Color(0xFF2563EB);
  static const Color accentBlueLt = Color(0xFF3B82F6);
  static const Color accentNavy   = Color(0xFF1E3A8A);
  static const Color accentGold   = Color(0xFFD97706);
  static const Color accentTeal   = Color(0xFF0D9488);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textMuted     = Color(0xFF6B7280);
  static const Color textDisabled  = Color(0xFF9CA3AF);
  static const Color textHint      = Color(0xFFD1D5DB);
  static const Color statusNew        = Color(0xFF2563EB);
  static const Color statusContacted  = Color(0xFF7C3AED);
  static const Color statusFollowup   = Color(0xFFD97706);
  static const Color statusReplied    = Color(0xFF059669);
  static const Color statusInterested = Color(0xFF10B981);
  static const Color statusClosed     = Color(0xFF6B7280);
  static const Color verdictProceed = Color(0xFF059669);
  static const Color verdictHold    = Color(0xFFD97706);
  static const Color verdictRevoke  = Color(0xFFDC2626);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error   = Color(0xFFDC2626);
  static const Color info    = Color(0xFF2563EB);
  static const Color border  = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color groqColor  = Color(0xFF2563EB);
  static const Color cfColor    = Color(0xFFF6821F);
  static const Color llamaColor = Color(0xFF6366F1);
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x06000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 40, offset: Offset(0, 12)),
  ];
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new': return statusNew;
      case 'contacted': return statusContacted;
      case 'followup due': case 'followup_due': return statusFollowup;
      case 'replied': return statusReplied;
      case 'interested': return statusInterested;
      case 'closed': return statusClosed;
      default: return textMuted;
    }
  }

  static Color getVerdictColor(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'proceed': return verdictProceed;
      case 'revoke': return verdictRevoke;
      default: return verdictHold;
    }
  }
}
