import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lead_model.dart';
import '../core/constants/app_colors.dart';
import 'status_badge.dart';

class LeadTile extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback? onTap, onDelete, onEmail;
  final Function(String)? onStatusChanged;
  const LeadTile({super.key, required this.lead, this.onTap,
      this.onStatusChanged, this.onDelete, this.onEmail});

  @override
  Widget build(BuildContext context) {
    final sc = AppColors.getStatusColor(lead.status);
    return Slidable(
      endActionPane: ActionPane(motion: const BehindMotion(), extentRatio: 0.38, children: [
        SlidableAction(onPressed: (_) => onEmail?.call(),
          backgroundColor: AppColors.accentBlue.withOpacity(0.12),
          foregroundColor: AppColors.accentBlue,
          icon: Icons.email_outlined, label: 'Email',
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))),
        SlidableAction(onPressed: (_) => onDelete?.call(),
          backgroundColor: AppColors.error.withOpacity(0.12),
          foregroundColor: AppColors.error,
          icon: Icons.delete_outline, label: 'Delete',
          borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12))),
      ]),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow),
          child: Row(children: [
            Container(width: 4, height: 80,
              decoration: BoxDecoration(color: sc, borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)))),
            const SizedBox(width: 12),
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(lead.initials,
                  style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w800, color: sc)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(children: [
                Expanded(child: Text(lead.companyName,
                    style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                StatusBadge(status: lead.status, compact: true),
              ]),
              if (lead.contactPerson?.isNotEmpty == true)
                Text(lead.contactPerson!, style: GoogleFonts.nunitoSans(
                    fontSize: 11, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
              Text(lead.email, style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                if (lead.city != null) ...[
                  const Icon(Icons.location_on_outlined, size: 10, color: AppColors.textDisabled),
                  const SizedBox(width: 2),
                  Text('${lead.city}', style: GoogleFonts.nunitoSans(fontSize: 10, color: AppColors.textDisabled)),
                  const SizedBox(width: 8),
                ],
                if (lead.isFollowupDue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text('⚠ Due', style: GoogleFonts.nunitoSans(
                        fontSize: 9, color: AppColors.warning, fontWeight: FontWeight.w700))),
              ]),
            ])),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (lead.whatsapp?.isNotEmpty == true)
                  _iconBtn(Icons.chat_bubble_outline, AppColors.success,
                      () => _openWhatsApp(lead.whatsapp!)),
                const SizedBox(height: 5),
                _iconBtn(Icons.mail_outline, AppColors.accentBlue, () => onEmail?.call()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(7)),
      child: Icon(icon, size: 14, color: color)));

  void _openWhatsApp(String number) async {
    final clean = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
