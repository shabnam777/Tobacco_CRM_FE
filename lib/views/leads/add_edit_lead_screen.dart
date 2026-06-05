import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/leads_provider.dart';
import '../../models/lead_model.dart';
import '../../core/constants/app_colors.dart';

class AddEditLeadScreen extends ConsumerStatefulWidget {
  final LeadModel? existingLead;
  const AddEditLeadScreen({super.key, this.existingLead});
  @override
  ConsumerState<AddEditLeadScreen> createState() => _State();
}

class _State extends ConsumerState<AddEditLeadScreen> {
  final _key = GlobalKey<FormState>();
  bool _saving = false;
  bool get _editing => widget.existingLead != null;
  late final _co,_ct,_em,_ph,_wa,_ci,_wb,_to,_em2,_li,_no,_ta,_pr;
  late String _country, _status, _tradeType;

  static const _countries  = ['UAE','Saudi Arabia','Kuwait','Qatar','Bahrain','Oman','India','Other'];
  static const _tradeTypes = ['Importer & Distributor','Wholesale Distributor','Retail Chain & Wholesale','General Trading','Free Zone Re-exporter','Import-Export Company','Specialist Tobacco Trader','FMCG Distributor','Other'];
  static const _statuses   = ['New','Contacted','Followup Due','Replied','Interested','Closed'];

  @override
  void initState() {
    super.initState();
    final l = widget.existingLead;
    _co = TextEditingController(text: l?.companyName ?? '');
    _ct = TextEditingController(text: l?.contactPerson ?? '');
    _em = TextEditingController(text: l?.email ?? '');
    _ph = TextEditingController(text: l?.phone ?? '');
    _wa = TextEditingController(text: l?.whatsapp ?? '');
    _ci = TextEditingController(text: l?.city ?? '');
    _wb = TextEditingController(text: l?.website ?? '');
    _to = TextEditingController(text: l?.annualTurnover ?? '');
    _em2= TextEditingController(text: l?.employeeCount ?? '');
    _li = TextEditingController(text: l?.licenseNo ?? '');
    _no = TextEditingController(text: l?.notes ?? '');
    _ta = TextEditingController(text: l?.tags.join(', ') ?? '');
    _pr = TextEditingController(text: l?.products.join(', ') ?? '');
    _country = l?.country ?? 'UAE';
    _status = l?.status ?? 'New';
    _tradeType = l?.tradeType ?? 'Importer & Distributor';
  }

  @override
  void dispose() {
    for (final c in [_co,_ct,_em,_ph,_wa,_ci,_wb,_to,_em2,_li,_no,_ta,_pr]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgPrimary,
    appBar: AppBar(backgroundColor: AppColors.bgSecondary,
      leading: IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted), onPressed: () => Navigator.pop(context)),
      title: Text(_editing ? 'Edit Lead' : 'New Lead', style: GoogleFonts.syne(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      actions: [TextButton(onPressed: _saving ? null : _save,
        child: Text('Save', style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w700,
            color: _saving ? AppColors.textDisabled : AppColors.accentBlue)))]),
    body: Form(key: _key, child: ListView(padding: const EdgeInsets.all(14), children: [
      _sec('Contact Info', Icons.person_outline, [
        _f(_co, 'Company Name *', validator: (v) => v?.isEmpty == true ? 'Required' : null),
        _f(_ct, 'Contact Person'),
        _f(_em, 'Email *', keyboard: TextInputType.emailAddress,
          validator: (v) { if (v?.isEmpty == true) return 'Required'; if (!RegExp(r'.+@.+\..+').hasMatch(v!)) return 'Invalid email'; return null; }),
        _f(_ph, 'Phone', keyboard: TextInputType.phone),
        _f(_wa, 'WhatsApp', hint: '+971XXXXXXXXX', keyboard: TextInputType.phone),
        _f(_wb, 'Website', keyboard: TextInputType.url),
      ]),
      const SizedBox(height: 12),
      _sec('Location', Icons.location_on_outlined, [
        _dr('Country', _country, _countries, (v) => setState(() => _country = v!)),
        _f(_ci, 'City'),
      ]),
      const SizedBox(height: 12),
      _sec('Business Details', Icons.work_outline, [
        _dr('Trade Type', _tradeType, _tradeTypes, (v) => setState(() => _tradeType = v!)),
        _dr('Status', _status, _statuses, (v) => setState(() => _status = v!)),
        _f(_to, 'Annual Turnover', hint: 'e.g. \$1M–\$5M'),
        _f(_em2, 'Employee Count', hint: 'e.g. 20–50'),
        _f(_li, 'Trade License No'),
      ]),
      const SizedBox(height: 12),
      _sec('Products & Tags', Icons.inventory_2_outlined, [
        _f(_pr, 'Products (comma-separated)', hint: 'Cigarettes, Beedi, Hookah', maxLines: 2),
        _f(_ta, 'Tags (comma-separated)', hint: 'tobacco, wholesale'),
      ]),
      const SizedBox(height: 12),
      _sec('Notes', Icons.notes_outlined, [_f(_no, 'Notes', maxLines: 4)]),
      const SizedBox(height: 20),
      SizedBox(height: 50, width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(_editing ? Icons.check : Icons.add),
          label: Text(_editing ? 'Update Lead' : 'Add Lead', style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      const SizedBox(height: 40),
    ])),
  );

  Widget _sec(String title, IconData icon, List<Widget> fields) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border), boxShadow: AppColors.cardShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 15, color: AppColors.accentBlue), const SizedBox(width: 8),
        Text(title, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary))]),
      const SizedBox(height: 14),
      ...fields.map((f) => Padding(padding: const EdgeInsets.only(bottom: 10), child: f)),
    ]));

  InputDecoration _dec(String l, {String? h}) => InputDecoration(labelText: l, hintText: h,
    filled: true, fillColor: AppColors.bgInput,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentBlue, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
    labelStyle: GoogleFonts.nunitoSans(fontSize: 13, color: AppColors.textMuted),
    hintStyle: GoogleFonts.nunitoSans(fontSize: 12, color: AppColors.textHint),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12));

  Widget _f(c, String l, {String? hint, TextInputType? keyboard, int maxLines = 1, String? Function(String?)? validator}) =>
    TextFormField(controller: c, keyboardType: keyboard, maxLines: maxLines, validator: validator,
      style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textPrimary), decoration: _dec(l, h: hint));

  Widget _dr(String l, String val, List<String> items, Function(String?) onChange) =>
    DropdownButtonFormField<String>(value: items.contains(val) ? val : items.first, dropdownColor: AppColors.bgCard,
      style: GoogleFonts.nunitoSans(fontSize: 14, color: AppColors.textPrimary), decoration: _dec(l),
      icon: const Icon(Icons.expand_more, color: AppColors.textMuted),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: onChange);

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'company_name': _co.text.trim(), 'contact_person': _ct.text.trim(),
      'email': _em.text.trim().toLowerCase(), 'phone': _ph.text.trim(),
      'whatsapp': _wa.text.trim(), 'country': _country, 'city': _ci.text.trim(),
      'website': _wb.text.trim(), 'trade_type': _tradeType, 'annual_turnover': _to.text.trim(),
      'employee_count': _em2.text.trim(), 'license_no': _li.text.trim(), 'notes': _no.text.trim(), 'status': _status,
      'tags': _ta.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      'products': _pr.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
    };
    bool ok = _editing
        ? await ref.read(leadsProvider.notifier).updateLead(widget.existingLead!.id, data)
        : await ref.read(leadsProvider.notifier).addLead(data);
    setState(() => _saving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? (_editing ? 'Lead updated ✅' : 'Lead added ✅') : '⚠ Saved locally'),
        backgroundColor: ok ? AppColors.success : AppColors.warning));
    }
  }
}
