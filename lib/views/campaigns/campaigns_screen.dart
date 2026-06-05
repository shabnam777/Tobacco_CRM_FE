import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/campaign_provider.dart';
import '../../models/campaign_model.dart';
import '../../core/constants/app_colors.dart';

class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});
  @override
  ConsumerState<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends ConsumerState<CampaignsScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(campaignProvider.notifier).loadCampaigns()); }

  @override
  Widget build(BuildContext context) {
    final camp = ref.watch(campaignProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(backgroundColor: AppColors.bgSecondary,
        title: Text('Campaigns', style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppColors.textMuted), onPressed: () => ref.read(campaignProvider.notifier).loadCampaigns())]),
      body: RefreshIndicator(color: AppColors.accentBlue,
        onRefresh: () => ref.read(campaignProvider.notifier).loadCampaigns(),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _stats(camp), const SizedBox(height: 16), _mondayCard(),
          const SizedBox(height: 16), _header('Campaign History', camp.campaigns.length),
          if (camp.status == CampaignStatus.loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.accentBlue)))
          else if (camp.campaigns.isEmpty)
            _empty()
          else
            ...camp.campaigns.map((c) => _CampaignCard(campaign: c)),
          const SizedBox(height: 80),
        ])),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newCampaign, backgroundColor: AppColors.accentBlue, foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('New Campaign', style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w700))),
    );
  }

  Widget _stats(CampaignState c) {
    final sent = c.campaigns.fold(0, (s, x) => s + x.sentEmails);
    final opened = c.campaigns.fold(0, (s, x) => s + x.openedEmails);
    final replied = c.campaigns.fold(0, (s, x) => s + x.repliedEmails);
    return Row(children: [
      _box('${c.campaigns.length}', 'Campaigns', AppColors.accentBlue),
      const SizedBox(width: 10), _box('$sent', 'Sent', AppColors.accentGold),
      const SizedBox(width: 10), _box(sent > 0 ? '${(opened/sent*100).toStringAsFixed(0)}%' : '0%', 'Open', AppColors.accentTeal),
      const SizedBox(width: 10), _box(sent > 0 ? '${(replied/sent*100).toStringAsFixed(0)}%' : '0%', 'Reply', AppColors.success),
    ]);
  }

  Widget _box(String v, String l, Color c) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
    child: Column(children: [
      Text(v, style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: c)),
      Text(l, style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted)),
    ])));

  Widget _mondayCard() {
    final days = (DateTime.monday - DateTime.now().weekday + 7) % 7;
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.accentBlue.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.schedule_send, color: Colors.white, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Monday Automation', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(days == 0 ? '🚀 Running today!' : 'Next run in $days day${days == 1 ? '' : 's'}',
              style: GoogleFonts.nunitoSans(fontSize: 12, color: Colors.white70)),
        ])),
        Switch(value: true, onChanged: (_) {}, activeColor: Colors.white, activeTrackColor: Colors.white38),
      ]));
  }

  Widget _header(String t, int n) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(t, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const Spacer(),
      Text('$n total', style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.textMuted)),
    ]));

  Widget _empty() => Padding(padding: const EdgeInsets.symmetric(vertical: 30),
    child: Column(children: [
      const Icon(Icons.campaign_outlined, size: 44, color: AppColors.textDisabled), const SizedBox(height: 10),
      Text('No campaigns yet', style: GoogleFonts.syne(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _newCampaign, icon: const Icon(Icons.add, size: 16), label: const Text('Create First Campaign')),
    ]));

  void _newCampaign() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('New Campaign', style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700)),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Campaign Name'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (ctrl.text.trim().isEmpty) return;
          await ref.read(campaignProvider.notifier).createCampaign({'name': ctrl.text.trim()});
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('Create')),
      ]));
  }
}

class _CampaignCard extends StatelessWidget {
  final CampaignModel campaign;
  const _CampaignCard({required this.campaign});
  @override
  Widget build(BuildContext context) {
    final color = campaign.status == 'Completed' ? AppColors.success
        : campaign.status == 'Running' ? AppColors.accentGold : AppColors.textMuted;
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(campaign.name, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(campaign.type, style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(campaign.status, style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: campaign.totalEmails > 0 ? campaign.sentEmails / campaign.totalEmails : 0,
            backgroundColor: AppColors.bgInput, color: AppColors.accentBlue, minHeight: 6)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _s('${campaign.sentEmails}/${campaign.totalEmails}', 'Sent'),
          _s('${campaign.openRate.toStringAsFixed(0)}%', 'Open'),
          _s('${campaign.replyRate.toStringAsFixed(0)}%', 'Reply'),
          _s(DateFormat('dd MMM').format(campaign.createdAt), 'Date'),
        ]),
      ]));
  }
  Widget _s(String v, String l) => Column(children: [
    Text(v, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    Text(l, style: GoogleFonts.nunitoSans(fontSize: 10, color: AppColors.textMuted)),
  ]);
}
