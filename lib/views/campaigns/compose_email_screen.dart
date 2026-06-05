import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/leads_provider.dart';
import '../../models/lead_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class ComposeEmailScreen extends ConsumerStatefulWidget {
  final LeadModel lead;
  final bool isFollowup;
  const ComposeEmailScreen({super.key, required this.lead, this.isFollowup = false});
  @override
  ConsumerState<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends ConsumerState<ComposeEmailScreen> {
  final _subCtrl  = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _template = AppStrings.emailColdOutreach;

  @override
  void initState() {
    super.initState();
    if (widget.isFollowup) _template = AppStrings.emailFollowupSoft;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(campaignProvider.notifier).clearGenerated());
  }

  @override
  void dispose() { _subCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final camp = ref.watch(campaignProvider);

    // Auto-populate fields when AI generates
    ref.listen(campaignProvider, (prev, next) {
      if (next.generatedSubject != null && next.generatedSubject != prev?.generatedSubject) {
        _subCtrl.text  = next.generatedSubject!;
        _bodyCtrl.text = next.generatedBody ?? '';
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        leading: IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Compose Email', style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text('To: ${widget.lead.companyName}', style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.accentBlue)),
        ])),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _recipientCard(),
        const SizedBox(height: 12),
        _templatePicker(),
        const SizedBox(height: 12),
        _aiCard(camp),
        const SizedBox(height: 12),
        _inputCard('Subject Line', _subCtrl, 'Enter subject...', 1),
        const SizedBox(height: 12),
        _inputCard('Email Body', _bodyCtrl, 'Write email or generate with AI...', 16),
        const SizedBox(height: 20),
        _sendBtn(camp),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _recipientCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
    child: Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(widget.lead.initials, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accentBlue)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.lead.companyName, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(widget.lead.email, style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.accentBlue)),
        if (widget.lead.contactPerson?.isNotEmpty == true)
          Text(widget.lead.contactPerson!, style: GoogleFonts.nunitoSans(fontSize: 11, color: AppColors.textMuted)),
      ])),
    ]));

  Widget _templatePicker() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Email Template', style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 6, children: AppStrings.emailTemplateTypes.map((t) {
        final sel = _template == t;
        return GestureDetector(
          onTap: () => setState(() => _template = t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? AppColors.accentBlue.withOpacity(0.1) : AppColors.bgInput,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? AppColors.accentBlue : AppColors.border)),
            child: Text(t, style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.w600,
                color: sel ? AppColors.accentBlue : AppColors.textMuted))));
      }).toList()),
    ]));

  Widget _aiCard(CampaignState camp) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentBlue.withOpacity(0.3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Email Generator', style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text('Groq LLaMA 70B', style: GoogleFonts.nunitoSans(fontSize: 10, color: AppColors.textMuted)),
        ])),
        if (camp.isGenerating) const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(color: AppColors.accentBlue, strokeWidth: 2)),
      ]),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: camp.isGenerating ? null : _generate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentBlue.withOpacity(0.1), foregroundColor: AppColors.accentBlue,
            elevation: 0, side: const BorderSide(color: AppColors.accentBlue),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12)),
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: Text(camp.isGenerating ? 'Generating...' : 'Generate with AI',
              style: GoogleFonts.nunitoSans(fontSize: 13, fontWeight: FontWeight.w700)))),
      if (camp.generatedBody != null) ...[
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 14), const SizedBox(width: 6),
            Text('Email generated — review & edit below', style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.success)),
          ])),
      ],
    ]));

  Widget _inputCard(String label, TextEditingController ctrl, String hint, int maxLines) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: ctrl, maxLines: maxLines,
            style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textPrimary, height: 1.6),
            decoration: InputDecoration(hintText: hint, filled: true, fillColor: AppColors.bgInput,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentBlue, width: 2)),
              contentPadding: const EdgeInsets.all(12))),
        ]));

  Widget _sendBtn(CampaignState camp) => SizedBox(height: 50, width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: camp.isSending ? null : _send,
      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      icon: camp.isSending
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.send_rounded, size: 18),
      label: Text(camp.isSending ? 'Sending...' : 'Send Email',
          style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w700))));

  Future<void> _generate() async {
    await ref.read(campaignProvider.notifier).generateEmail(
      companyName: widget.lead.companyName,
      contactPerson: widget.lead.contactPerson ?? '',
      templateType: _template);
  }

  Future<void> _send() async {
    if (_subCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a subject'))); return; }
    if (_bodyCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write the email body'))); return; }

    final ok = await ref.read(campaignProvider.notifier).sendEmail(
      leadId: widget.lead.id, toEmail: widget.lead.email,
      subject: _subCtrl.text.trim(), body: _bodyCtrl.text.trim(), templateType: _template);

    if (!mounted) return;
    if (ok) {
      // Instant status update — no refresh
      ref.read(leadsProvider.notifier).updateStatus(widget.lead.id, 'Contacted');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Email sent!'), backgroundColor: AppColors.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${ref.read(campaignProvider).error}'), backgroundColor: AppColors.error));
      ref.read(campaignProvider.notifier).resetStatus();
    }
  }
}
