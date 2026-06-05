import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;
  const StatusBadge({super.key, required this.status, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.getStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: compact ? 5 : 6, height: compact ? 5 : 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(status, style: GoogleFonts.nunitoSans(
            fontSize: compact ? 10 : 11, fontWeight: FontWeight.w700, color: c)),
      ]),
    );
  }
}

class StatusDropdown extends StatelessWidget {
  final String currentStatus;
  final Function(String) onChanged;
  static const _statuses = ['New','Contacted','Followup Due','Replied','Interested','Closed'];
  const StatusDropdown({super.key, required this.currentStatus, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.getStatusColor(currentStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statuses.contains(currentStatus) ? currentStatus : _statuses.first,
          isDense: true, dropdownColor: AppColors.bgCard,
          style: GoogleFonts.nunitoSans(fontSize: 13, fontWeight: FontWeight.w700, color: c),
          icon: const Icon(Icons.expand_more, color: AppColors.textMuted, size: 18),
          items: _statuses.map((s) {
            final sc = AppColors.getStatusColor(s);
            return DropdownMenuItem(value: s, child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(s, style: GoogleFonts.nunitoSans(fontSize: 13, fontWeight: FontWeight.w700, color: sc)),
            ]));
          }).toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}
