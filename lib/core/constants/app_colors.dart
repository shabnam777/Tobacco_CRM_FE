import 'package:flutter/material.dart';

class AppColors {
  // =========================
  // BACKGROUND (Dark SaaS)
  // =========================

  static const Color bgCard = Color.fromARGB(255, 45, 56, 79);
  static const Color bgInput = Color(0xFF16223A);
  static const bgPrimary = Color(0xFF0B1220); // deep navy
  static const bgSecondary = Color(0xFF0F1A2B); // card background
  static const bgTertiary = Color(0xFF14213D); // elevated surfaces
  // =========================
  // PRIMARY ACCENTS
  // =========================

  static const Color accentBlueLt = Color(0xFF60A5FA);
  static const Color accentNavy = Color(0xFF1E293B);
  static const Color accentGold = Color(0xFFF59E0B); // orange-gold
  static const Color accentTeal = Color(0xFF14B8A6);
  static const accentBlue = Color(0xFF4F8CFF);
  static const accentGreen = Color(0xFF22C55E);
  static const accentOrange = Color(0xFFF59E0B);
  static const accentPurple = Color(0xFFA78BFA);

  // =========================
  // TEXT COLORS (Dark UI)
  // =========================

  static const Color textDisabled = Color(0xFF64748B);
  static const Color textHint = Color(0xFF475569);

  // Text
  static const textPrimary = Color(0xFFE5E7EB);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);

  // Borders
  static const border = Color(0xFF1F2A44);

  // Status
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // =========================
  // STATUS COLORS (CRM logic)
  // =========================
  static const Color statusNew = Color(0xFF3B82F6);
  static const Color statusContacted = Color(0xFFA78BFA);
  static const Color statusFollowup = Color(0xFFF59E0B);
  static const Color statusReplied = Color(0xFF14B8A6);
  static const Color statusInterested = Color(0xFF22C55E);
  static const Color statusClosed = Color(0xFF64748B);

  // =========================
  // VERDICT COLORS
  // =========================
  static const Color verdictProceed = Color.fromARGB(255, 21, 140, 64);
  static const Color verdictHold = Color.fromARGB(255, 198, 127, 3);
  static const Color verdictRevoke = Color.fromARGB(255, 195, 36, 36);

  // =========================
  // SYSTEM COLORS
  // =========================

  static const Color info = Color(0xFF3B82F6);

  static const Color divider = Color(0xFF1B263B);

  // =========================
  // AI / INTEGRATION COLORS
  // =========================
  static const Color groqColor = Color(0xFF3B82F6);
  static const Color cfColor = Color(0xFFF97316);
  static const Color llamaColor = Color(0xFFA78BFA);

  // =========================
  // ICON SEMANTIC COLORS (NEW)
  // =========================
  static const Color iconPrimary = Color(0xFFE2E8F0);
  static const Color iconSecondary = Color(0xFF94A3B8);
  static const Color iconMuted = Color(0xFF64748B);

  static const Color iconSuccess = success;
  static const Color iconWarning = warning;
  static const Color iconError = error;
  static const Color iconInfo = info;

  static const Color iconBlue = accentBlue;
  static const Color iconGreen = accentGreen;
  static const Color iconOrange = accentGold;
  static const Color iconPurple = accentPurple;

  // =========================
  // SHADOWS (Dark UI)
  // =========================
  static const cardShadow = [
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    )
  ];
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x33000000), blurRadius: 50, offset: Offset(0, 18)),
  ];

  // =========================
  // GRADIENTS (Premium SaaS look)
  // =========================
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // =========================
  // HELPERS
  // =========================
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return statusNew;
      case 'contacted':
        return statusContacted;
      case 'followup due':
      case 'followup_due':
        return statusFollowup;
      case 'replied':
        return statusReplied;
      case 'interested':
        return statusInterested;
      case 'closed':
        return statusClosed;
      default:
        return textMuted;
    }
  }

  static Color getVerdictColor(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'proceed':
        return verdictProceed;
      case 'revoke':
        return verdictRevoke;
      default:
        return verdictHold;
    }
  }
}
