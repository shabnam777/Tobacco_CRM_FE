import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/leads_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../models/lead_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'add_edit_lead_screen.dart';
import '../campaigns/compose_email_screen.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final String leadId;
  final bool openEmail;
  const LeadDetailScreen({super.key, required this.leadId, this.openEmail = false});
  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lead = _getLead();
      if (lead != null) {
        ref.read(campaignProvider.notifier).loadEmailLogs(lead.id);
        if (widget.openEmail) _openEmail(lead);
      }
    });
  }

  @override
  void dispose() { _tabs.dispose(); _noteCtrl.dispose(); super.dispose(); }

  LeadModel? _getLead() {
    try { return ref.read(leadsProvider).leads.firstWhere((l) => l.id == widget.leadId); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final leadsState = ref.watch(leadsProvider);
    LeadModel? lead;
    try { lead = leadsState.leads.firstWhere((l) => l.id == widget.leadId); } catch (_) {}

    if (lead == null) {
      return Scaffold(appBar: AppBar(backgroundColor: AppColors.bgSecondary),
          body: const Center(child: Text('Lead not found')));
    }

    final sc = AppColors.getStatusColor(lead.status);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(expandedHeight: 190, pinned: true, backgroundColor: AppColors.bgSecondary,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context)),
            actions: [IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditLeadScreen(existingLead: lead))))],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(
                    colors: [sc.withOpacity(0.1), AppColors.bgSecondary],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 52, height: 52,
                      decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: sc.withOpacity(0.3))),
                      child: Center(child: Text(lead!.initials, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800, color: sc)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(lead!.companyName, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      if (lead!.contactPerson?.isNotEmpty == true)
                        Text(lead.contactPerson!, style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      StatusBadge(status: lead.status),
                    ])),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    _hs('${lead.followupCount}', 'Followups', AppColors.accentPurple),
                    const SizedBox(width: 16),
                    if (lead.lastContacted != null)
                      _hs(DateFormat('dd MMM').format(lead.lastContacted!), 'Last Contact', AppColors.accentTeal),
                    const SizedBox(width: 16),
                    if (lead.annualTurnover?.isNotEmpty == true)
                      _hs(lead.annualTurnover!, 'Turnover', AppColors.accentGold),
                  ]),
                ]),
              ),
            ),
          ),
        ],
        body: Column(children: [
          Container(color: AppColors.bgSecondary,
            child: TabBar(controller: _tabs, indicatorColor: AppColors.accentBlue,
              labelColor: AppColors.accentBlue, unselectedLabelColor: AppColors.textMuted,
              dividerColor: AppColors.border,
              labelStyle: GoogleFonts.nunitoSans(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: const [Tab(text: 'Details'), Tab(text: 'Emails'), Tab(text: 'Notes')])),
          Expanded(child: TabBarView(controller: _tabs, children: [
            _DetailsTab(lead: lead),
            _EmailsTab(lead: lead),
            _NotesTab(lead: lead, ctrl: _noteCtrl),
          ])),
        ]),
      ),
      bottomNavigationBar: Container(
        color: AppColors.bgSecondary,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        child: Row(children: [
          if (lead.whatsapp?.isNotEmpty == true) ...[
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _openWhatsApp(lead!.whatsapp!),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: Text('WhatsApp', style: GoogleFonts.nunitoSans(fontSize: 13, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
          ],
          Expanded(flex: 2, child: ElevatedButton.icon(
            onPressed: () => _openEmail(lead!),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.send_outlined, size: 16),
            label: Text('Send Email', style: GoogleFonts.nunitoSans(fontSize: 13, fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }

  Widget _hs(String v, String l, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(v, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
    Text(l, style: GoogleFonts.nunitoSans(fontSize: 10, color: AppColors.textMuted)),
  ]);

  void _openEmail(LeadModel lead) => Navigator.push(context, MaterialPageRoute(builder: (_) => ComposeEmailScreen(lead: lead)));
  void _openWhatsApp(String num) async {
    final clean = num.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(Uri.parse('https://wa.me/$clean'));
  }
}

class _DetailsTab extends ConsumerWidget {
  final LeadModel lead;
  const _DetailsTab({required this.lead});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(padding: const EdgeInsets.all(14), children: [
    _card([
      _row('Status', StatusDropdown(currentStatus: lead.status,
          onChanged: (s) => ref.read(leadsProvider.notifier).updateStatus(lead.id, s))),
      if (lead.email.isNotEmpty) _copyRow(context, 'Email', lead.email),
      if (lead.phone?.isNotEmpty == true) _txtRow('Phone', lead.phone!),
      if (lead.city?.isNotEmpty == true) _txtRow('Location', '${lead.city}, ${lead.country}'),
      if (lead.website?.isNotEmpty == true) _txtRow('Website', lead.website!),
      if (lead.tradeType?.isNotEmpty == true) _txtRow('Trade Type', lead.tradeType!),
      if (lead.annualTurnover?.isNotEmpty == true) _txtRow('Turnover', lead.annualTurnover!),
      if (lead.licenseNo?.isNotEmpty == true) _copyRow(context, 'License', lead.licenseNo!),
    ]),
    if (lead.notes?.isNotEmpty == true) ...[const SizedBox(height: 10), _card([_txtRow('Notes', lead.notes!, multiline: true)])],
    if (lead.tags.isNotEmpty) ...[
      const SizedBox(height: 10),
      _card([
        Text('Tags', style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: lead.tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: AppColors.accentTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentTeal.withOpacity(0.25))),
          child: Text('#$t', style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.accentTeal, fontWeight: FontWeight.w600)))).toList()),
      ]),
    ],
    const SizedBox(height: 80),
  ]);

  Widget _card(List<Widget> c) => Container(padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: c.map((w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w)).toList()));

  Widget _row(String l, Widget c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted)), const SizedBox(height: 4), c]);

  Widget _txtRow(String l, String v, {bool multiline = false}) => _row(l, Text(v,
      style: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600, height: multiline ? 1.5 : 1)));

  Widget _copyRow(BuildContext ctx, String l, String v) => _row(l, GestureDetector(
    onTap: () { Clipboard.setData(ClipboardData(text: v)); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$l copied'))); },
    child: Row(children: [
      Expanded(child: Text(v, style: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.accentBlue, fontWeight: FontWeight.w600))),
      const Icon(Icons.copy_outlined, size: 14, color: AppColors.textMuted)])));
}

class _EmailsTab extends ConsumerWidget {
  final LeadModel lead;
  const _EmailsTab({required this.lead});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(campaignProvider).emailLogs;
    if (logs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.mail_outline, size: 44, color: AppColors.textDisabled), const SizedBox(height: 10),
      Text('No emails sent yet', style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComposeEmailScreen(lead: lead))),
          icon: const Icon(Icons.send_outlined, size: 16), label: const Text('Send First Email')),
    ]));
    return ListView.builder(padding: const EdgeInsets.all(14), itemCount: logs.length,
      itemBuilder: (_, i) {
        final l = logs[i];
        return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(l.statusIcon, style: const TextStyle(fontSize: 16)), const SizedBox(width: 8),
              Expanded(child: Text(l.subject, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: (l.isSuccessful ? AppColors.success : AppColors.error).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(l.status.toUpperCase(), style: GoogleFonts.nunitoSans(fontSize: 9, fontWeight: FontWeight.w800, color: l.isSuccessful ? AppColors.success : AppColors.error))),
            ]),
            const SizedBox(height: 4),
            Text(l.templateType, style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.accentBlue)),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(l.sentAt), style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted)),
          ]));
      });
  }
}

class _NotesTab extends ConsumerStatefulWidget {
  final LeadModel lead;
  final TextEditingController ctrl;
  const _NotesTab({required this.lead, required this.ctrl});
  @override
  ConsumerState<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<_NotesTab> {
  @override
  Widget build(BuildContext context) {
    final leadsState = ref.watch(leadsProvider);
    LeadModel lead = widget.lead;
    try { lead = leadsState.leads.firstWhere((l) => l.id == widget.lead.id); } catch (_) {}

    return Column(children: [
      Expanded(child: lead.noteHistory.isEmpty
          ? Center(child: Text('No notes yet', style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textMuted)))
          : ListView.builder(padding: const EdgeInsets.all(14), itemCount: lead.noteHistory.length,
              itemBuilder: (_, i) {
                final n = lead.noteHistory[i];
                return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.note, style: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
                    const SizedBox(height: 4),
                    Text(DateFormat('dd MMM yyyy, hh:mm a').format(n.timestamp), style: GoogleFonts.nunitoSans(fontSize: 10, color: AppColors.textMuted)),
                  ]));
              })),
      Container(color: AppColors.bgSecondary, padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(child: TextField(controller: widget.ctrl, maxLines: 2,
            style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'Add a note...', filled: true, fillColor: AppColors.bgInput,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentBlue, width: 2)),
              contentPadding: const EdgeInsets.all(12)))),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              if (widget.ctrl.text.trim().isEmpty) return;
              await ref.read(leadsProvider.notifier).addNote(widget.lead.id, widget.ctrl.text.trim());
              widget.ctrl.clear();
            },
            child: Container(width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
        ])),
    ]);
  }
}
