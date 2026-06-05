import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Map<String, dynamic> _s;
  bool _saving = false;
  bool _showGroq = false, _showCF = false, _showLlama = false, _showEmail = false;

  late final TextEditingController _backendCtrl, _groqCtrl, _cfTokenCtrl,
      _cfAccountCtrl, _llamaCtrl, _emailKeyCtrl, _senderEmailCtrl,
      _senderNameCtrl, _companyCtrl, _cityCtrl, _productCtrl;

  @override
  void initState() {
    super.initState();
    _s = StorageService.getSettings();
    _backendCtrl     = TextEditingController(text: _s['backendUrl']     ?? 'http://localhost:8000');
    _groqCtrl        = TextEditingController(text: _s['groqApiKey']     ?? '');
    _cfTokenCtrl     = TextEditingController(text: _s['cfApiToken']     ?? '');
    _cfAccountCtrl   = TextEditingController(text: _s['cfAccountId']    ?? '');
    _llamaCtrl       = TextEditingController(text: _s['llamaApiKey']    ?? '');
    _emailKeyCtrl    = TextEditingController(text: _s['emailApiKey']    ?? '');
    _senderEmailCtrl = TextEditingController(text: _s['senderEmail']    ?? '');
    _senderNameCtrl  = TextEditingController(text: _s['senderName']     ?? '');
    _companyCtrl     = TextEditingController(text: _s['companyName']    ?? '');
    _cityCtrl        = TextEditingController(text: _s['companyCity']    ?? 'India');
    _productCtrl     = TextEditingController(text: _s['defaultProduct'] ?? '');
  }

  @override
  void dispose() {
    for (final c in [_backendCtrl, _groqCtrl, _cfTokenCtrl, _cfAccountCtrl,
      _llamaCtrl, _emailKeyCtrl, _senderEmailCtrl, _senderNameCtrl,
      _companyCtrl, _cityCtrl, _productCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: Text('Settings', style: GoogleFonts.syne(
            fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text('Save', style: GoogleFonts.nunitoSans(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: _saving ? AppColors.textDisabled : AppColors.accentBlue)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Company & Sender', Icons.business_outlined, AppColors.accentBlue, [
            _field(_companyCtrl, 'Company Name'),
            _field(_cityCtrl, 'City / Country', hint: 'Mumbai, India'),
            _field(_productCtrl, 'Default Product'),
            _field(_senderNameCtrl, 'Sender Name'),
            _field(_senderEmailCtrl, 'Sender Email',
                keyboard: TextInputType.emailAddress),
          ]),
          const SizedBox(height: 12),
          _section('Backend URL', Icons.cloud_outlined, AppColors.accentNavy, [
            _field(_backendCtrl, 'Backend URL'),
            _infoBox(
              'Web (local):   http://localhost:8000\n'
              'Emulator:       http://10.0.2.2:8000\n'
              'Real device:  http://192.168.X.X:8000\n'
              'Production:    https://yourdomain.com',
              AppColors.accentBlue),
          ]),
          const SizedBox(height: 12),
          _section('🔵  Groq AI (Required)', Icons.auto_awesome_outlined, AppColors.groqColor, [
            _secret(_groqCtrl, 'Groq API Key', _showGroq,
                () => setState(() => _showGroq = !_showGroq), hint: 'gsk_...'),
            _linkHint('Free key → console.groq.com/keys', AppColors.groqColor),
          ]),
          const SizedBox(height: 12),
          _section('🟠  Cloudflare Workers AI', Icons.cloud_queue_outlined, AppColors.cfColor, [
            _field(_cfAccountCtrl, 'CF Account ID',
                hint: 'From dash.cloudflare.com (top right)'),
            _secret(_cfTokenCtrl, 'CF API Token', _showCF,
                () => setState(() => _showCF = !_showCF),
                hint: 'Needs "Workers AI:Edit" permission'),
            _infoBox('Free: 10,000 neurons/day\ndash.cloudflare.com → Workers AI',
                AppColors.cfColor),
          ]),
          const SizedBox(height: 12),
          _section('🟣  Meta Llama API (Optional)', Icons.smart_toy_outlined, AppColors.llamaColor, [
            _secret(_llamaCtrl, 'Llama API Key', _showLlama,
                () => setState(() => _showLlama = !_showLlama)),
            _linkHint('llama.developer.meta.com  or  api.together.xyz', AppColors.llamaColor),
            _infoBox('Leave empty — app works fine with only Groq', AppColors.textMuted),
          ]),
          const SizedBox(height: 12),
          _section('Email Provider', Icons.email_outlined, AppColors.accentGold, [
            _dropdown('Provider', _s['emailProvider'] ?? 'resend', ['resend', 'brevo'],
                (v) => setState(() => _s['emailProvider'] = v)),
            _secret(_emailKeyCtrl, 'Email API Key', _showEmail,
                () => setState(() => _showEmail = !_showEmail)),
          ]),
          const SizedBox(height: 12),
          _section('Automation', Icons.schedule_outlined, AppColors.accentTeal, [
            _switch('Monday Email Automation', _s['mondayAutomation'] == true,
                (v) => setState(() => _s['mondayAutomation'] = v)),
            _switch('Friday Auto-Discovery', _s['fridayDiscovery'] == true,
                (v) => setState(() => _s['fridayDiscovery'] = v)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 50, width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text('Save All Settings', style: GoogleFonts.nunitoSans(
                  fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: Text('Sign Out', style: GoogleFonts.nunitoSans(
                fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, Color color, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 15, color: color), const SizedBox(width: 8),
            Text(title, style: GoogleFonts.syne(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          ...children.map((w) =>
              Padding(padding: const EdgeInsets.only(bottom: 10), child: w)),
        ]),
      );

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint,
    filled: true, fillColor: AppColors.bgInput,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accentBlue, width: 2)),
    labelStyle: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.textMuted),
    hintStyle: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.textHint),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Widget _field(TextEditingController c, String label,
      {String? hint, TextInputType? keyboard}) =>
      TextField(
        controller: c, keyboardType: keyboard,
        style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textPrimary),
        decoration: _dec(label, hint: hint),
      );

  Widget _secret(TextEditingController c, String label, bool visible,
      VoidCallback toggle, {String? hint}) =>
      TextField(
        controller: c, obscureText: !visible,
        style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textPrimary),
        decoration: _dec(label, hint: hint).copyWith(
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textMuted, size: 18),
            onPressed: toggle,
          ),
        ),
      );

  Widget _dropdown(String label, String value, List<String> items,
      Function(String?) onChange) =>
      DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        dropdownColor: AppColors.bgCard,
        style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textPrimary),
        decoration: _dec(label),
        icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
        items: items.map((i) =>
            DropdownMenuItem(value: i, child: Text(i.toUpperCase()))).toList(),
        onChanged: onChange,
      );

  Widget _switch(String label, bool value, Function(bool) onChange) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.nunitoSans(fontSize: 13,
            color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        Switch(value: value, onChanged: onChange, activeColor: AppColors.accentBlue),
      ]);

  Widget _infoBox(String text, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: GoogleFonts.nunitoSans(
        fontSize: 11, color: color, height: 1.6)),
  );

  Widget _linkHint(String text, Color color) => Row(children: [
    Icon(Icons.open_in_new, size: 12, color: color), const SizedBox(width: 5),
    Expanded(child: Text(text, style: GoogleFonts.nunitoSans(
        fontSize: 12, color: color, fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline),
        overflow: TextOverflow.ellipsis)),
  ]);

  Future<void> _save() async {
    setState(() => _saving = true);
    await StorageService.saveSettings({
      ..._s,
      'backendUrl':    _backendCtrl.text.trim(),
      'groqApiKey':    _groqCtrl.text.trim(),
      'cfApiToken':    _cfTokenCtrl.text.trim(),
      'cfAccountId':   _cfAccountCtrl.text.trim(),
      'llamaApiKey':   _llamaCtrl.text.trim(),
      'emailApiKey':   _emailKeyCtrl.text.trim(),
      'senderEmail':   _senderEmailCtrl.text.trim(),
      'senderName':    _senderNameCtrl.text.trim(),
      'companyName':   _companyCtrl.text.trim(),
      'companyCity':   _cityCtrl.text.trim(),
      'defaultProduct':_productCtrl.text.trim(),
    });
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Settings saved'),
        backgroundColor: AppColors.success,
      ));
    }
  }
}
